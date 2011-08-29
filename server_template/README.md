# Introduction

You have now installed all those custom scripts on your server! Congratulations!

But, if you have been using Zabbix for more than a week you'll notice you can't do squad until you have added templates to the zabbix server, unless you want to shot yourself in the head... Templates are awesome and prevent you from replicating the same work over and over...

Templates are server / system agnostic and allow you to be applied to any of your configured servers (host).

Zabbix templates are a collection of:

* Items, to allow the gathering of specific items (1 item = 1 value retrieved),
* Triggers, to allow you to alert(!) whenever an item reach some threshold defined in the trigger,
* Graphs, are a graphical representation of your items, allowing you to compare items against one another. For instance for MySQL, you may want to see graph that display MySQL select vs. update vs. insert vs. delete.

# Zabbix server setup

From that server, you may either want to download locally the templates (.xml files) and (perform changes) import them on your Zabbix server one by one.

Then, apply those templates to your hosts and get them to grab the dat you want...

You might (for sure) want to create screens to display relevant info for your platform. Notice that the screens are not exportable natively from Zabbix and that you'll have to re-create them if you change you server. Don't forget about dynamic graphs if you want to build say .. server status!


