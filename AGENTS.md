# Sparking Cards AGENTS.md

## Project Overview
This project is an advanced fighting Roblox game built with Luau

## Code Style
- Use Luau strict mode.
- Use snake-case.
- Follow stylua configurations
- Use type-casting for things Luau can't inference
- Use function generics when applicable and necessary
- Define types when needed
- Use type exports in modules
- Make sure to typecheck variadics
- Use type unions and intersections
- Do not nest if statements unless necessary
- Ignore typechecking libraries if they cannot be typechecked easily
- Place types many scripts/modules might need in the Shared\Replicated\Types\typemarshaller.luau file

## PR instructions
- Update sourcemap.json file by using `rojo sourcemap` before commiting
- If you decide to add dependencies, make sure to use `wally install` then update the sourcemap

## Testing instructions
- Use TestEZ to test Luau files