module til.modules;

import core.sys.posix.dlfcn;
import std.experimental.logger : trace;
import std.string : strip, toStringz;

import til.nodes;


bool importModule(SubProgram program, string modulePath)
{
    return importModule(program, modulePath, modulePath);
}
bool importModule(SubProgram program, string modulePath, string prefix)
{
    // Check if the submodule is already available (as a "builtin"):
    CommandHandler[string] source;
    trace("importModule: ", program, " ", modulePath, " as ", prefix);
    trace(" availableModules:", program.availableModules);
    source = program.availableModules.get(modulePath, null);

    if (source is null)
    {
        try {
            source = importFromSharedLibrary(modulePath, prefix);
        }
        catch(Exception)
        {
            return false;
        }
    }

    program.importNamesFrom(source, prefix);
    return true;
}

// Import commands from a .so:
CommandHandler[string] importFromSharedLibrary(string libraryPath, string moduleAlias)
{
    // We don't want users informing the library preffix and suffix:
    libraryPath = "lib" ~ libraryPath ~ ".so";
    auto libraryPathZ = libraryPath.toStringz;

    // lh = "library handler"
    void* lh = dlopen(libraryPathZ, RTLD_LAZY);
    if (!lh)
    {
        const char* error = dlerror();
        throw new Exception("dlopen error: " ~ to!string(error));
    }
    trace(libraryPath ~ " succesfully loaded.");

    // Get the commands from inside the shared object:
    auto getCommands = cast(CommandHandler[string] function())dlsym(lh, "getCommands");
    const char* error = dlerror();
    if (error)
    {
        throw new Exception("dlsym error: " ~ to!string(error));
    }
    auto libraryCommands = getCommands();

    return libraryCommands;
};


void importNamesFrom(SubProgram program, CommandHandler[string]source, string prefix)
{
    foreach(name, command; source)
    {
        string cmdPath;
        if (name is null)
        {
            cmdPath = prefix;
        }
        else
        {
            cmdPath = prefix ~ "." ~ name;
        }
        program.commands[cmdPath] = command;
    }
}
