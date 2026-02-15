# Figura-Synth
Note Block Sythesizer for Figura Mod, template JSON file included. Uses [json.lua by rxi](https://github.com/rxi/json.lua).  
With thanks to yingcan.

```template.json``` and all music JSON files goes in ```figura/data/music```

```Synth.lua``` and ```json.lua``` goes in your avatar folder

#### Functions:  
```play(filename)``` to start playing music and add file to queue  
```playLocal(filename)``` to start playing music locally and add file to queue. **TURN OFF SYNCED PINGS** if you use this function.  
```stop()``` to stop playing music  
```clear()``` to clear the queue  
```toggleLoop()``` to toggle looping

#### Chat Commands:
```.play filename``` to start playing music  
```.stop``` to stop playing music  
```.localplay filename``` to play music but only locally (for example if you don't want to disturb other people). **TURN OFF SYNCED PINGS** if you use this command.
```.loop``` to toggle looping
