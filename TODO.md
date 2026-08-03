### to many things need to be done at once so use this to keep track of tasks
#### one rule for this checklist is for each time one is completed explain bellow how

- [x] 1. make list_mark_files keybindings moduler so all of them run checks 
- did not have to use a new function but using the nav_mark func that has a built in check to make sure the mark is set before teleporting

> [!IMPORTANT]
> for alot of the things that use the perproject marks use something like vim.json.encode or decode 

- [x] 2. need to make the projects use file paths from the root of the project aka the .git dir and also use per project saving 
- did not really have to find the root as i am using :. instead of :t and it seems to be working fine

- [x] 3. need to be more consistent with what tables the marks use by that i mean i use vim.fn.getmarklist and the get_teleport_marks use one and keep it that way
- mistake

- [x] 4. need to be able to find the root of the project first before file paths are able to be displayed -> to lead of from this use the :. in order to start the search for the git repo
- [x] 5. need to have a setup function for each project just once in order to find the per project markings
- [x] 6. a good idea might be to have a sort of telescope type of searching for the marks
- [x] 7. rewrite the module system to use more lua style oop and have just one require module for simple use
- [x] 8. next and prev apis for going through marks
- [x] 9. preview maybe for the file marks and tab opening 
> tabs now done still need a preview buffer maybe like the head of the file

- 10. add save/change status for files and if they are affected by gut diffs kinda like neotree
  - [x] altered files
  - [x] git status on files just bland color letters but may want to add color later
  - [ ] color status on git status
- [x] 11. list of things needed for opts -> to add on to this the way to think of this is to make a table in config.lua and pass the needed options to other things
  - [x] preselect for the cursor 
  - [x] border overrides for windows 
  - [x] position on the screen topleft center topright etc...
  - [x] preview size length if at all so 50 is default but can go larger or * for like entire file

- [x] 12. small bug with buffer iteration using next and prev 
> Problem if a file is added to the list then its not counted in the next and prev listing option

- 13. split vert or hor for files
