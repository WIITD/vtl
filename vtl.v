module main

import os
import term
import term.ui as tui
import json

enum State {
  choose_file
  run_app
}

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
  state   State
  file    string
  dir     []string
  conf_dir string
  term    Term
  run     Run
}

fn main() {
  mut app := &App {}
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
  app.run.arg = 0

  if os.user_os() == "linux" {app.conf_dir = "/.config/vtl/"}
  else if os.user_os() == "windows" {app.conf_dir = "\\AppData\\Roaming\\vtl\\"}

  if os.exists("${os.home_dir()}${app.conf_dir}") == false {os.mkdir("${os.home_dir()}${app.conf_dir}") or {exit(4)}}

  if os.args.len > 1 {
    app.file = os.args[1]
    load_json(x)
    app.state = State.run_app
  }
  else {
    app.dir = os.ls("${os.home_dir()}${app.conf_dir}") or {exit(4)}
    app.state = State.choose_file
  }
}


fn event(t &tui.Event, x voidptr) {
  mut app := &App(x)

  match app.state {
    .choose_file {
      if t.typ == .key_down && t.code == .escape {exit(0)}
      if t.typ == .key_down && t.code == .up {
        app.run.arg -= 1
        if app.run.arg < 0 {app.run.arg = app.dir.len-1}
      }
      if t.typ == .key_down && t.code == .down {
        app.run.arg += 1
        if app.run.arg > app.dir.len-1 {app.run.arg = 0}
      }
      if t.typ == .key_down && t.code == .enter {
        println(" loading...")
        app.file = "${os.home_dir()}${app.conf_dir}${app.dir[app.run.arg]}"
        load_json(x)
        app.run.arg = 0
        app.state = State.run_app
      }
    }

    .run_app {
      if t.typ == .key_down && t.code == .escape {exit(0)}
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
        go os.execute("${app.run.app} ${app.run.args[app.run.arg]} &")
      }
      if t.typ == .key_down && t.code == .backspace {
        println(" returning...")
        app.run.arg = 0
        app.dir = os.ls("${os.home_dir()}${app.conf_dir}") or {exit(4)}
        app.state = .choose_file
      }
    }
  }
}

fn frame(x voidptr) {
  mut app := &App(x)
  app.term.width, app.term.height = term.get_terminal_size()
  app.tui.clear()
  app.tui.horizontal_separator(2)
  app.tui.horizontal_separator(app.term.height-1)
  match app.state {
    .choose_file {
      app.tui.draw_text(5, 4, "Dir: '~/.config/vtl/'")
      app.tui.draw_text(5, 6, "Files: ")
      for i, arg in app.dir {
        if app.run.arg == i {
          app.tui.set_bg_color(r: 255, g: 255, b: 255)
          app.tui.set_color(r: 0, g: 0, b: 0)
          app.tui.draw_text(10, 8+i, "${i+1}: '${arg}'")
          app.tui.reset_color()
          app.tui.reset_bg_color()
        }
        else {app.tui.draw_text(10, 8+i, "${i+1}: '${arg}'")}
      }
      app.tui.draw_text(5, app.term.height-2,"enter: select")
    }

    .run_app {
      app.tui.draw_text(5, 4, "App: '${app.run.app}'")
      app.tui.draw_text(5, 6, "Args: ")
      for i, arg in app.run.args {
        if app.run.arg == i {
          app.tui.set_bg_color(r: 255, g: 255, b: 255)
          app.tui.set_color(r: 0, g: 0, b: 0)
          app.tui.draw_text(10, 8+i, "${i+1}: '${arg}'")
          app.tui.reset_color()
          app.tui.reset_bg_color()
        }
        else {app.tui.draw_text(10, 8+i, "${i+1}: '${arg}'")}
      }
      app.tui.draw_text(5, app.term.height-2,"enter: select | backspace: return")
    }
  }
  app.tui.set_cursor_position(0, 0)

  app.tui.reset()
  app.tui.flush()
}

fn load_json(x voidptr) {
  mut app := &App(x)
  file := os.read_file(app.file) or {
    exit(2)
	}

  json := json.decode(Run, file) or {
	  exit(3)
  }
  app.run.app = json.app
  app.run.args = json.args
}
