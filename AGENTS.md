# Sparking Cards AGENTS.md

## Project Overview
This project is an advanced fighting Roblox game built with Luau

## Code Style
- Use Luau strict mode.
- Use snake-case for variable names, otherwise use any variable case
- Follow stylua configurations
- Use type-casting for things Luau can't inference
- Use function generics when applicable and necessary
- Define types when needed
- Use type exports in modules
- Make sure to typecheck variadics
- Use type unions and intersections
- Do not nest if statements unless necessary
- Ignore typechecking libraries if they cannot be typechecked easily
- Type exports scripts/modules might need in the Shared\Replicated\Types\typemarshaller.luau file
- Document code in moonwave style
- Use native Luau functions when necessary
- Do not use functions/methods that dont exist; instead, comment a 
utility that the developer can implement themselves. An alternative is to look at the API/libray you're using and choose the correct function.

## Code Optimization
- Avoid additional computation in RunService loops

## PR instructions
- Update sourcemap.json file by using `rojo sourcemap` before commiting
- If you decide to add dependencies, make sure to use `wally install` then update the sourcemap

## Testing instructions
- Use TestEZ to test Luau files