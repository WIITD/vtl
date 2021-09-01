module main

import os
import term
import term.ui as tui
import json

struct Term {
mut:
  width   int
  height  int
}

struct Run {
mut:
  app     string
  args    []string
  arg     int
}

struct App {
mut:
  tui     &tui.Context = 0
  file    string
  term    Term
  run     Run
}

fn main() {
  mut app := &App {}
  os.system("ls cfg")
  app.file = os.input("choose file(name.extension): ")
  app.tui = tui.init(
    user_data: app
    init_fn : init
    event_fn: event
    frame_fn: frame
    hide_cursor: true
  )
  app.tui.run() ?
}


fn init(x voidptr) {
  mut app := &App(x)
  //if os.args.len < 2 {
  //  exit(0)
  //}
  app.run.arg = 0

  mut file := os.read_file("cfg/${app.file}") or {
		eprintln("Error: Cannot find or open file: $err")
		exit(0)
	}

  mut json := json.decode(Run, file) or {
    eprintln("Failed to decode json, error: $err")
	  exit(0)
  }
  app.run.app = json.app
  app.run.args = json.args
}

fn event(t &tui.Event, x voidptr) {
  mut app := &App(x)
  if t.typ == .key_down && t.code == .escape {
    exit(0)
  }
  if t.typ == .key_down && t.code == .up {
    app.run.arg -= 1

    if app.run.arg < 0 {app.run.arg = app.run.args.len-1}
  }

  if t.typ == .key_down && t.code == .down {
    app.run.arg += 1

    if app.run.arg > app.run.args.len-1 {app.run.arg = 0}
  }

  if t.typ == .key_down && t.code == .enter {
    println(" running...")
    os.execute("${app.run.app} ${app.run.args[app.run.arg]}")
  }
}

fn frame(x voidptr) {
  mut app := &App(x)
  app.term.width, app.term.height = term.get_terminal_size()
  app.tui.clear()
  app.tui.set_bg_color(r: 255, g: 255, b: 255)
  app.tui.draw_empty_rect(2, 2, app.term.width-1, app.term.height-1)
  app.tui.reset_bg_color()
  app.tui.draw_text(5, 4, "App: '${app.run.app}'")
  for i, arg in app.run.args {
    if app.run.arg == i {
      app.tui.set_bg_color(r: 255, g: 255, b: 255)
      app.tui.set_color(r: 0, g: 0, b: 0)
      app.tui.draw_text(5, 6+i, "${i+1}: '${arg}'")
      app.tui.reset_color()
      app.tui.reset_bg_color()
    }
    else {app.tui.draw_text(5, 6+i, "${i+1}: '${arg}'")}
  }
  app.tui.set_cursor_position(0, 0)

  app.tui.reset()
  app.tui.flush()
}
