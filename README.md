# vtl - v terminal launcher
simple terminal based launcher for apps

tested on linux and windows

# config
app can be configured through json files  

example:  
```
{
  "app": "path/to/app"
  "args": [
    "path/to/...",
    "path/to/...",
    ...
  ]
}
```
important: on window please use "\\\" while declaring the path otherwise app will crash  

app, upon launching, will display list of files json files from '~/.config/vtl/', or    
simply drag and drop json file on executable or pass it as an argument  

# building 
to build this app all you need is v compiler

```
v vtl.v
```

# licence
MIT
