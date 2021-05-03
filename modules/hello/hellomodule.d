import std.stdio : writeln;

import til.nodes;


extern (C) CommandHandler[string] getCommands()
{
    CommandHandler[string] commands;

    commands["print"] = (string path, CommandContext context)
    {
        Items arguments = context.items;
        foreach(arg; arguments)
        {
            writeln(arg.toString);
        }

        context.exitCode = ExitCode.CommandSuccess;
        return context;
    };

    return commands;
}
