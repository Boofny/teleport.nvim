### to many things need to be done at once so use this to keep track of tasks
#### one rule for this checklist is for each time one is completed explain bellow how

- [x] 1. make list_mark_files keybindings moduler so all of them run checks 
- did not have to use a new function but using the navMark func that has a built in check to make sure the mark is set before teleporting

> [!IMPORTANT]
> for alot of the things that use the perproject marks use something like vim.json.encode or decode 

- [x] 2. need to make the projects use file paths from the root of the project aka the .git dir and also use per project saving 
- did not really have to find the root as i am using :. instead of :t and it seems to be working fine

3. need to be more consistent with what tables the marks use by that i mean i use vim.fn.getmarklist and the get_teleport_marks use one and keep it that way
4. need to be able to find the root of the project first before file paths are able to be displayed
5. need to have a setup function for each project just once in order to find the per project markings
