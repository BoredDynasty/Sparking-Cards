# Sparking Cards AGENTS.md

## Project Overview
This project is an advanced fighting Roblox game built with Luau.
This project also uses Google's design language: Material 3

## Code Style
- Use Luau strict mode.
- Use snake-case for variable names, otherwise use any other case
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
- Always use Native Luau functions when applicable
- When an instance or function doesn't exist, comment a 
utility or instance that the developer can implement themselves.
- When scripting UI, look at other scripts managing UI as inspiration. Use animation modules like catmull-rom spline or "spr."

## Code Optimization
- Avoid unnecesary computation in RunService loops

## PR instructions
- If you decide to add external dependencies, make sure to use `wally install` then update the sourcemap
