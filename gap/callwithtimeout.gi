#############################################################################
##
#F  IO_CallWithTimeout( <timeout>, <func>, ... )  
##         . . call a function with a time limit
#F  IO_CallWithTimeoutList( <timeout>, <func>, <arglist> )  
##
##

InstallGlobalFunction("IO_CallWithTimeout",
        function( timeout, func, arg... )
    return IO_CallWithTimeoutList(timeout, func, arg);
end );

InstallGlobalFunction("IO_CallWithTimeoutList",
    function(timeout, func, arglist )
    local  process, nano, seconds, microseconds, callfunc, timeoutrec, ret;
    process := function(name, scale)
        local  val;
        if IsBound(timeout.(name)) then
            val := timeout.(name);
            if IsRat(val) or IsFloat(val) then
                nano := nano + Int(val*scale);
            else
                Error("IO_CallWithTimeout[List]: can't understand period of ",val," ",name,". Ignoring.");
            fi;
        fi;
    end;
    if IsInt(timeout) then
        nano := 1000*timeout;
    else
        if not IsRecord(timeout) then
            Error("IO_CallWithTimeout[List]: timeout must be an integer or record");
            return fail;
        fi;
        nano := 0;
        process("nanoseconds",1);
        process("microseconds",1000);
        process("milliseconds",1000000);
        process("seconds",10^9);
        process("minutes",60*10^9);
        process("hours",3600*10^9);
        process("days",24*3600*10^9);
        process("weeks",7*24*3600*10^9);
    fi;
    if nano < 0 then
        Error("Negative timeout is not permitted");
        return fail;
    fi;
    seconds := QuoInt(nano, 10^9);
    microseconds := QuoInt(nano mod 10^9, 1000);
    if seconds = 0 and microseconds = 0 then
        # zero or tiny timeout. just simulate timeout now
        return fail;
    fi;
    # make sure it's a small int. Cap timeouts at about 8 years on
    # 32 bit systems
    seconds := Minimum(seconds,2^(8*GAPInfo.BytesPerVariable-4)-1);

    callfunc := function() return CallFuncListWrap(func, arglist); end;
    timeoutrec := rec(TimeOut := rec(tv_sec := seconds, tv_usec := microseconds));
    ret := ParDoByFork( [callfunc], [ [] ], timeoutrec);
    if ret = [ ] then
        return [ false ];
    elif ret[1] = fail then
        return [ fail ];
    elif Length(ret[1]) > 0 then
        return [ true, ret[1][1] ];
    else
        return [ true ];
    fi;
end);
