#!/usr/bin/env python3
"""Backend-neutral UniOpt line-advisor model and GUI frontends."""

from __future__ import annotations

from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, HTTPServer
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import secrets
import shlex
import subprocess
import sys
import threading
from urllib.parse import parse_qs, urlparse
import webbrowser


CONTROL_IDS = {"interface.help", "interface.gui"}


def _truth(value):
    return value is True or value == "true"


@dataclass
class FieldState:
    item: dict
    value: object
    included: bool = False


class AdvisorModel:
    """Schema state that serializes controls into exact argv elements."""

    def __init__(self, schema):
        if schema.get("schema_version") != 1:
            raise ValueError("unsupported UniOpt schema version")
        self.schema = schema
        self.items = [
            item
            for item in schema["items"]
            if not item.get("internal")
            and item["id"] not in CONTROL_IDS
            and item.get("ui", {}).get("control", "auto") != "hidden"
        ]
        self.states = {}
        for item in self.items:
            if item.get("repeatable") or item["kind"] == "remainder":
                value = []
            elif item["type"] in ("boolean", "tristate"):
                value = item["default"] if item["default"] is not None else (
                    "inherit" if item["type"] == "tristate" else "false"
                )
            else:
                value = item["default"] if item["default"] is not None else ""
            included = item["kind"] == "positional" and item.get("required", False)
            self.states[item["id"]] = FieldState(item, value, included)
        self.conditions = self._conditions()

    def _conditions(self):
        result = {item["id"]: [] for item in self.items}
        for constraint in self.schema.get("constraints", []):
            members = constraint["members"]
            kind = constraint["kind"]
            for member in members:
                if member not in result:
                    continue
                others = [value for value in members if value != member]
                if kind == "requires" and member == members[0]:
                    result[member].append("Requires " + members[1])
                elif kind == "requires" and member == members[1]:
                    result[member].append("Required when " + members[0] + " is supplied")
                elif kind in ("mutex", "conflicts"):
                    result[member].append("Exclusive with " + ", ".join(others))
                elif kind in ("one-of", "one_of"):
                    result[member].append("Choose exactly one of " + ", ".join(members))
        return result

    def set(self, item_id, value, included=True):
        state = self.states[item_id]
        state.value = value
        state.included = included

    def reset(self):
        fresh = AdvisorModel(self.schema)
        self.states = fresh.states

    @staticmethod
    def _boolean_spelling(item, value):
        desired = "true" if _truth(value) else "false"
        if item.get("store_constant") is not None:
            return (item.get("long") or item.get("short")) if item.get("store_constant") == desired else None
        if desired == "true":
            return item.get("long") or item.get("short")
        return item.get("negative_long")

    def build_args(self):
        options, positionals, remainder = [], [], []
        for item in self.items:
            state = self.states[item["id"]]
            if not state.included:
                continue
            spelling = item.get("long") or item.get("short")
            value = state.value
            if item["kind"] == "alias":
                if _truth(value):
                    options.append(spelling)
            elif item["type"] == "boolean":
                selected = self._boolean_spelling(item, value)
                if selected:
                    options.append(selected)
            elif item["type"] == "tristate":
                if value == "true":
                    options.append(spelling)
                elif value == "false" and item.get("negative_long"):
                    options.append(item["negative_long"])
            elif item["kind"] == "remainder":
                remainder.extend(value)
            elif item["kind"] == "positional":
                positionals.append(str(value))
            elif item.get("repeatable"):
                for member in value:
                    options.extend((spelling, str(member)))
            elif item.get("store_constant") is not None:
                options.append(spelling)
            else:
                options.extend((spelling, str(value)))
        return options + positionals + (["--"] + remainder if remainder else [])

    def command_display(self, fixed_program):
        return shlex.join([*fixed_program, *self.build_args()])


class AdvisorRunner:
    def __init__(self, uniopt_bin, schema_file, schema_function, program, cwd=None):
        self.uniopt_bin = str(Path(uniopt_bin).resolve())
        self.schema_file = str(Path(schema_file).resolve())
        self.schema_function = schema_function
        self.program = list(program)
        self.cwd = cwd or os.getcwd()

    def validate(self, args):
        return subprocess.run(
            [self.uniopt_bin, "validate", self.schema_file, self.schema_function, "--", *args],
            cwd=self.cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def run(self, args, timeout=None):
        return subprocess.run(
            [*self.program, *args],
            cwd=self.cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
        )


def load_schema(uniopt_bin, schema_file, schema_function):
    completed = subprocess.run(
        [uniopt_bin, "json", schema_file, schema_function],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return json.loads(completed.stdout)


def _label(item):
    return item.get("ui", {}).get("label") or item.get("long") or item.get("short") or item.get("metavar") or item["id"]


def run_tk(model, runner):
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk

    root = tk.Tk()
    root.title(model.schema["command"] + " — UniOpt advisor")
    root.geometry("900x760")
    ttk.Label(root, text=model.schema["command"], font=("TkDefaultFont", 18, "bold")).pack(anchor="w", padx=12, pady=(10, 0))
    ttk.Label(root, text=model.schema.get("summary", "")).pack(anchor="w", padx=12, pady=(0, 8))
    notebook = ttk.Notebook(root); notebook.pack(fill="both", expand=True, padx=10)
    tabs = {}
    for name in ("Basic", "Advanced"):
        outer = ttk.Frame(notebook); notebook.add(outer, text=name)
        canvas = tk.Canvas(outer, highlightthickness=0); scroll = ttk.Scrollbar(outer, orient="vertical", command=canvas.yview)
        body = ttk.Frame(canvas); window = canvas.create_window((0, 0), window=body, anchor="nw")
        body.bind("<Configure>", lambda _e, c=canvas: c.configure(scrollregion=c.bbox("all")))
        canvas.bind("<Configure>", lambda e, c=canvas, w=window: c.itemconfigure(w, width=e.width))
        canvas.configure(yscrollcommand=scroll.set); canvas.pack(side="left", fill="both", expand=True); scroll.pack(side="right", fill="y")
        tabs[name] = body
    bindings = {}

    class ListEditor(ttk.Frame):
        def __init__(self, parent, changed, item):
            ttk.Frame.__init__(self, parent); self.rows=[]; self.changed=changed; self.item=item
            ttk.Button(self, text="Add value", command=self.add).pack(anchor="w")
        def add(self, value=""):
            row=ttk.Frame(self); row.pack(fill="x", pady=2); text=tk.Text(row, height=2, wrap="none"); text.insert("1.0", value); text.pack(side="left", fill="x", expand=True)
            ttk.Button(row, text="Remove", command=lambda: self.remove(row, text)).pack(side="right", padx=4)
            if self.item["type"]=="path": ttk.Button(row,text="Browse…",command=lambda:self.browse(text)).pack(side="right")
            text.bind("<KeyRelease>", lambda _e: self.changed()); self.rows.append((row,text)); self.changed()
        def browse(self,text):
            ui=self.item.get("ui",{}); mode=ui.get("file_mode","auto"); selected=filedialog.askdirectory() if mode=="directory" or ui.get("control")=="directory" else (filedialog.asksaveasfilename() if mode=="save" else filedialog.askopenfilename())
            if selected: text.delete("1.0","end"); text.insert("1.0",selected); self.changed()
        def remove(self,row,text): row.destroy(); self.rows.remove((row,text)); self.changed()
        def get(self): return [text.get("1.0","end-1c") for _row,text in self.rows]

    def sync():
        for item_id, getter in bindings.items():
            value, included = getter(); model.set(item_id, value, included)
        command_var.set(model.command_display(runner.program))

    for item in model.items:
        state=model.states[item["id"]]; ui=item.get("ui",{}); parent=tabs["Advanced" if ui.get("advanced") else "Basic"]
        group=ttk.LabelFrame(parent, text=ui.get("group") or "Options"); group.pack(fill="x", padx=6, pady=5)
        ttk.Label(group, text=_label(item), font=("TkDefaultFont", 10, "bold")).pack(anchor="w")
        ttk.Label(group, text=item.get("help", ""), wraplength=780).pack(anchor="w")
        condition="; ".join(model.conditions.get(item["id"],[]))
        if condition: ttk.Label(group, text="Conditional: "+condition, foreground="#9a5b00").pack(anchor="w")
        if item.get("repeatable") or item["kind"]=="remainder":
            editor=ListEditor(group,sync,item); editor.pack(fill="x"); bindings[item["id"]]=lambda e=editor: (e.get(), bool(e.rows)); continue
        if item["type"]=="boolean" or item["kind"]=="alias":
            var=tk.BooleanVar(value=_truth(state.value)); dirty=[False]
            def changed(d=dirty): d[0]=True; sync()
            widget=ttk.Checkbutton(group, text="Enabled", variable=var, command=changed); widget.pack(anchor="w")
            bindings[item["id"]]=lambda v=var,d=dirty: (v.get(), d[0]); continue
        if item["type"]=="tristate":
            var=tk.StringVar(value=state.value); dirty=[False]; widget=ttk.Combobox(group,textvariable=var,values=("inherit","true","false"),state="readonly"); widget.pack(fill="x")
            widget.bind("<<ComboboxSelected>>",lambda _e,d=dirty:(d.__setitem__(0,True),sync()))
            bindings[item["id"]]=lambda v=var,d=dirty: (v.get(), d[0]); continue
        included=tk.BooleanVar(value=state.included); line=ttk.Frame(group); line.pack(fill="x")
        ttk.Checkbutton(line,text="Include",variable=included,command=sync).pack(side="left")
        var=tk.StringVar(value=state.value)
        if item["type"]=="enum": widget=ttk.Combobox(line,textvariable=var,values=item.get("choices",[]),state="readonly")
        else: widget=ttk.Entry(line,textvariable=var,show="*" if ui.get("control")=="password" else "")
        widget.pack(side="left",fill="x",expand=True); var.trace_add("write",lambda *_args, inc=included: (inc.set(True),sync()))
        if item["type"]=="path":
            def browse(v=var,inc=included,u=ui):
                mode=u.get("file_mode","auto"); selected=filedialog.askdirectory() if mode=="directory" or u.get("control")=="directory" else (filedialog.asksaveasfilename() if mode=="save" else filedialog.askopenfilename())
                if selected: v.set(selected); inc.set(True)
            ttk.Button(line,text="Browse…",command=browse).pack(side="right",padx=4)
        bindings[item["id"]]=lambda v=var,inc=included:(v.get(),inc.get())

    preview=ttk.LabelFrame(root,text="Command line"); preview.pack(fill="x",padx=10,pady=6)
    command_var=tk.StringVar(); ttk.Entry(preview,textvariable=command_var,state="readonly").pack(fill="x",padx=5,pady=4)
    output=tk.Text(root,height=9,wrap="word"); output.pack(fill="both",expand=False,padx=10,pady=5)
    buttons=ttk.Frame(root); buttons.pack(fill="x",padx=10,pady=8)
    def finish(label, completed):
        output.delete("1.0","end"); output.insert("end",f"{label}: {completed.returncode}\nstdout:\n{completed.stdout}\nstderr:\n{completed.stderr}")
    def execute():
        sync(); confirmation=model.schema.get("ui",{}).get("confirm","")
        if confirmation and not messagebox.askyesno("Confirm execution",confirmation): return
        def work():
            checked=runner.validate(model.build_args())
            completed=checked if checked.returncode else runner.run(model.build_args())
            root.after(0,finish,"validation" if checked.returncode else "exit",completed)
        threading.Thread(target=work,daemon=True).start()
    ttk.Button(buttons,text="Run",command=execute).pack(side="left"); ttk.Button(buttons,text="Close",command=root.destroy).pack(side="right")
    sync()
    if os.environ.get("UNIOPT_GUI_SMOKE_EXIT"): root.after(100,root.destroy)
    root.mainloop()


def run_qt(model, runner):
    from PySide6 import QtCore, QtWidgets
    app=QtWidgets.QApplication.instance() or QtWidgets.QApplication(sys.argv[:1]); window=QtWidgets.QMainWindow(); window.setWindowTitle(model.schema["command"]+" — UniOpt advisor"); window.resize(920,760)
    central=QtWidgets.QWidget(); layout=QtWidgets.QVBoxLayout(central); title=QtWidgets.QLabel(f"<h2>{model.schema['command']}</h2><p>{model.schema.get('summary','')}</p>"); layout.addWidget(title)
    tabs=QtWidgets.QTabWidget(); layout.addWidget(tabs,1); tab_layouts={}; bindings={}
    for name in ("Basic","Advanced"):
        scroll=QtWidgets.QScrollArea(); scroll.setWidgetResizable(True); body=QtWidgets.QWidget(); box=QtWidgets.QVBoxLayout(body); box.addStretch(); scroll.setWidget(body); tabs.addTab(scroll,name); tab_layouts[name]=box
    class ListEditor(QtWidgets.QWidget):
        def __init__(self, changed, item):
            super().__init__(); self.changed=changed; self.item=item; self.rows=[]; self.box=QtWidgets.QVBoxLayout(self)
            add=QtWidgets.QPushButton("Add value"); add.clicked.connect(lambda: self.add()); self.box.addWidget(add)
        def add(self, value=""):
            row=QtWidgets.QWidget(); layout=QtWidgets.QHBoxLayout(row); edit=QtWidgets.QPlainTextEdit(); edit.setPlainText(value); edit.setMaximumHeight(70)
            remove=QtWidgets.QPushButton("Remove"); remove.clicked.connect(lambda _checked=False,r=row,e=edit:self.remove(r,e)); edit.textChanged.connect(self.changed)
            layout.addWidget(edit,1)
            if self.item["type"]=="path":
                browse=QtWidgets.QPushButton("Browse…"); browse.clicked.connect(lambda _checked=False,e=edit:self.browse(e)); layout.addWidget(browse)
            layout.addWidget(remove); self.box.insertWidget(self.box.count()-1,row); self.rows.append((row,edit)); self.changed()
        def browse(self,edit):
            ui=self.item.get("ui",{}); mode=ui.get("file_mode","auto"); selected=QtWidgets.QFileDialog.getExistingDirectory(window,"Choose directory") if mode=="directory" or ui.get("control")=="directory" else (QtWidgets.QFileDialog.getSaveFileName(window,"Choose output file")[0] if mode=="save" else QtWidgets.QFileDialog.getOpenFileName(window,"Choose file")[0])
            if selected: edit.setPlainText(selected); self.changed()
        def remove(self,row,edit):
            self.rows.remove((row,edit)); row.deleteLater(); self.changed()
        def values(self): return [edit.toPlainText() for _row,edit in self.rows]
    def sync():
        for item_id,getter in bindings.items(): value,included=getter(); model.set(item_id,value,included)
        command.setText(model.command_display(runner.program))
    for item in model.items:
        state=model.states[item["id"]]; ui=item.get("ui",{}); group=QtWidgets.QGroupBox(_label(item)); box=QtWidgets.QVBoxLayout(group); box.addWidget(QtWidgets.QLabel(item.get("help","")))
        condition="; ".join(model.conditions.get(item["id"],[]))
        if condition: label=QtWidgets.QLabel("Conditional: "+condition); label.setStyleSheet("color:#9a5b00"); box.addWidget(label)
        if item.get("repeatable") or item["kind"]=="remainder":
            edit=ListEditor(sync,item); box.addWidget(edit); bindings[item["id"]]=lambda e=edit:(e.values(),bool(e.rows));
        elif item["type"]=="boolean" or item["kind"]=="alias":
            check=QtWidgets.QCheckBox("Enabled"); check.setChecked(_truth(state.value)); box.addWidget(check); dirty=[False]
            def changed(_value,d=dirty): d[0]=True; sync()
            check.toggled.connect(changed); bindings[item["id"]]=lambda c=check,d=dirty:(c.isChecked(),d[0])
        elif item["type"]=="tristate":
            combo=QtWidgets.QComboBox(); combo.addItems(["inherit","true","false"]); combo.setCurrentText(str(state.value)); box.addWidget(combo); dirty=[False]
            combo.currentTextChanged.connect(lambda _v,d=dirty:(d.__setitem__(0,True),sync())); bindings[item["id"]]=lambda c=combo,d=dirty:(c.currentText(),d[0])
        else:
            row=QtWidgets.QHBoxLayout(); include=QtWidgets.QCheckBox("Include"); include.setChecked(state.included); row.addWidget(include)
            if item["type"]=="enum": edit=QtWidgets.QComboBox(); edit.addItems(item.get("choices",[])); edit.setCurrentText(str(state.value)); edit.currentTextChanged.connect(lambda _v,i=include:(i.setChecked(True),sync())); getter=lambda e=edit:e.currentText()
            else: edit=QtWidgets.QLineEdit(str(state.value)); edit.setEchoMode(QtWidgets.QLineEdit.Password if ui.get("control")=="password" else QtWidgets.QLineEdit.Normal); edit.textEdited.connect(lambda _v,i=include:(i.setChecked(True),sync())); getter=lambda e=edit:e.text()
            row.addWidget(edit,1); include.toggled.connect(sync)
            if item["type"]=="path":
                button=QtWidgets.QPushButton("Browse…")
                def browse(_checked=False,e=edit,i=include,u=ui):
                    mode=u.get("file_mode","auto"); selected=QtWidgets.QFileDialog.getExistingDirectory(window,"Choose directory") if mode=="directory" or u.get("control")=="directory" else (QtWidgets.QFileDialog.getSaveFileName(window,"Choose output file")[0] if mode=="save" else QtWidgets.QFileDialog.getOpenFileName(window,"Choose file")[0])
                    if selected: e.setText(selected); i.setChecked(True); sync()
                button.clicked.connect(browse); row.addWidget(button)
            box.addLayout(row); bindings[item["id"]]=lambda g=getter,i=include:(g(),i.isChecked())
        target=tab_layouts["Advanced" if ui.get("advanced") else "Basic"]; target.insertWidget(target.count()-1,group)
    advisor=QtWidgets.QGroupBox("Command line"); advisor_box=QtWidgets.QVBoxLayout(advisor); command=QtWidgets.QLineEdit(); command.setReadOnly(True); advisor_box.addWidget(command); layout.addWidget(advisor)
    output=QtWidgets.QPlainTextEdit(); output.setReadOnly(True); layout.addWidget(output)
    buttons=QtWidgets.QHBoxLayout(); run_button=QtWidgets.QPushButton("Run"); close_button=QtWidgets.QPushButton("Close"); buttons.addWidget(run_button); buttons.addStretch(); buttons.addWidget(close_button); layout.addLayout(buttons)
    class Signals(QtCore.QObject): done=QtCore.Signal(str,object)
    signals=Signals(); signals.done.connect(lambda label,c: output.setPlainText(f"{label}: {c.returncode}\nstdout:\n{c.stdout}\nstderr:\n{c.stderr}"))
    def execute():
        sync(); confirmation=model.schema.get("ui",{}).get("confirm","")
        if confirmation and QtWidgets.QMessageBox.question(window,"Confirm execution",confirmation)!=QtWidgets.QMessageBox.Yes:return
        def work():
            checked=runner.validate(model.build_args()); signals.done.emit("validation",checked) if checked.returncode else signals.done.emit("exit",runner.run(model.build_args()))
        threading.Thread(target=work,daemon=True).start()
    run_button.clicked.connect(execute); close_button.clicked.connect(window.close); window.setCentralWidget(central); sync(); window.show()
    if os.environ.get("UNIOPT_GUI_SMOKE_EXIT"): QtCore.QTimer.singleShot(100,window.close)
    return app.exec()


def run_web(model, runner, converter, port=0, open_browser=True):
    loader=importlib.machinery.SourceFileLoader("uniopt_html_renderer",str(converter)); spec=importlib.util.spec_from_loader(loader.name,loader); module=importlib.util.module_from_spec(spec); loader.exec_module(module)
    token=secrets.token_urlsafe(24); run_path="/"+token+"/run"; browse_path="/"+token+"/browse"; page=module.render_page(model.schema,run_path,browse_path).encode()
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            parsed=urlparse(self.path)
            if parsed.path==browse_path:
                try:
                    requested=parse_qs(parsed.query).get("path",[runner.cwd])[0]; path=Path(requested).expanduser(); path=(Path(runner.cwd)/path if not path.is_absolute() else path).resolve()
                    if not path.is_dir(): path=path.parent
                    entries=[]
                    for entry in sorted(path.iterdir(),key=lambda value:(not value.is_dir(),value.name.casefold()))[:1000]:
                        entries.append({"name":entry.name,"path":str(entry),"directory":entry.is_dir()})
                    body=json.dumps({"path":str(path),"entries":entries},ensure_ascii=False).encode()
                    self.send_response(200); self.send_header("Content-Type","application/json; charset=utf-8"); self.send_header("Content-Length",str(len(body))); self.end_headers(); self.wfile.write(body)
                except (OSError,ValueError) as error: self.send_error(400,str(error))
                return
            if parsed.path not in ("/","/"+token,"/"+token+"/"): self.send_error(404); return
            self.send_response(200); self.send_header("Content-Type","text/html; charset=utf-8"); self.send_header("Content-Length",str(len(page))); self.end_headers(); self.wfile.write(page)
        def do_POST(self):
            if self.path!=run_path or self.headers.get_content_type()!="application/json": self.send_error(404); return
            try:
                length=int(self.headers.get("Content-Length","0")); payload=json.loads(self.rfile.read(length)); args=payload["args"]
                if not isinstance(args,list) or any(not isinstance(x,str) for x in args): raise ValueError("args must be a string array")
                checked=runner.validate(args); completed=checked if checked.returncode else runner.run(args); body=json.dumps({"status":completed.returncode,"stdout":completed.stdout,"stderr":completed.stderr}).encode()
                self.send_response(200); self.send_header("Content-Type","application/json"); self.send_header("Content-Length",str(len(body))); self.end_headers(); self.wfile.write(body)
            except Exception as error:
                body=json.dumps({"status":2,"stdout":"","stderr":str(error)}).encode(); self.send_response(400); self.send_header("Content-Type","application/json"); self.send_header("Content-Length",str(len(body))); self.end_headers(); self.wfile.write(body)
        def log_message(self, *_args): pass
    server=HTTPServer(("127.0.0.1",port),Handler); url=f"http://127.0.0.1:{server.server_port}/{token}"; print("UniOpt advisor: "+url,flush=True)
    if open_browser: threading.Timer(.1,webbrowser.open,args=(url,)).start()
    try: server.serve_forever()
    except KeyboardInterrupt: pass
    finally: server.server_close()
