Erlang Trace Analyzer (for OS X)
================================

This is a very very PRIMITIVE Erlang Trace Analyzer, which allows you to load an output
trace from a systemtap run. It shows the life cycle of every Erlang process: creating, 
sched in, sched out and exiting.

This tool is inspired by a profiling tool for Barrelfish multi-kernel operating system
(www.barrelfish.org). But this one is much more trivial than that one. When there are many
processes in trace file, the graph generated is more a visualizing toy than a useful
analyzing tool.

It works like this:

* Run systemtap with provided script (you should customize it to satisfy your needs)
* Run an Erlang program
* Save the trace output to a text file
* Load the text file with this tool
* It will spend some time to generate a sqlite db (the UI freezes during this period, my 
  bad)
* When the db is generated, trace graph is shown
* You can zoom in/out the graph, click on any bar to show detailed info in the box at left
  upper corner

sample\_data folder includes the bigbang benchmark and corresponding systemtap script.
trace\_100.txt is a sample trace output. trace\_100.pdf is the output pdf file of this 
analyzer.