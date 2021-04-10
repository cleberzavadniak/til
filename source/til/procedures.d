module til.procedures;

import std.conv : to;
import std.experimental.logger : trace;

import til.exceptions;
import til.ranges;
import til.nodes;


class Procedure
{
    string name;
    ListItem parameters;
    ListItem body;

    this(string name, ListItem parameters, ListItem body)
    {
        this.name = name;
        this.parameters = parameters;
        this.body = body;

        trace(
            "proc.define: ", this.name,
            "(", this.parameters, ")",
            ": ", this.body
        );
    }

    CommandContext run(string name, CommandContext context)
    {
        trace("proc.run: ", name);

        // TODO: cast it on constructor:
        SimpleList parameters = cast(SimpleList)this.parameters;

        // We open a new scope only because we
        // want a new namespace that do not
        // interfere with the caller one
        auto newContext = context;   // struct copy
        newContext.escopo = new Process(context.escopo);

        foreach(parameter; parameters.items)
        {
            if (newContext.size == 0)
            {
                throw new InvalidException(
                    "Not enough arguments passed to command"
                    ~ " \"" ~ name ~ "\"."
                );
            }
            string parameterName = parameter.asString;
            auto argument = newContext.pop();
            newContext.escopo[parameterName] = argument;
            trace(" argument ", parameterName, "=", argument);
        }

        trace(" procScope:", newContext.escopo);
        trace(" parentScope:", context.escopo);
        auto subprogram = (cast(SubList)this.body).subprogram;

        // RUN!
        trace(" RUN subprogram");
        newContext = newContext.escopo.run(subprogram, newContext);

        if (newContext.exitCode != ExitCode.Failure)
        {
            context.exitCode = ExitCode.CommandSuccess;
            trace(" PROC RETURNED");
            trace(" procScope:", newContext.escopo);
            trace(" parentScope:", context.escopo);

            // Now we must COPY the stack
            // and update context.size
            trace("  context.size:", context.size);
            trace("  newContext.size:", newContext.size);
            context.size = newContext.size;
            trace("  → context.size now is ", context.size);
            context.escopo.stack = newContext.escopo.stack;
            trace(" parentScope is now ", context.escopo);
            trace(" context is now ", context);
        }
        return context;
    }
}
