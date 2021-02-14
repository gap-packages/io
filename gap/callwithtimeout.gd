#############################################################################
##
#F  IO_CallWithTimeout( <timeout>, <func>, ... )
##         . . call a function with a time limit
#F  IO_CallWithTimeoutList( <timeout>, <func>, <arglist> )
##
##  <#GAPDoc Label="IO_CallWithTimeout">
##  <Index>Timeouts</Index>
##  <ManSection>
##  <Func Name="IO_CallWithTimeout" Arg='timeout, func, ...'/>
##  <Func Name="IO_CallWithTimeoutList" Arg='timeout, func, arglist'/>
##
##  <Description>
##  <C>IO_CallWithTimeout</C> and <C>IO_CallWithTimeoutList</C> allow calling
##  a function with a limit on length of time it will run. The function is run
##  inside a copy of the current GAP session, so any changes it makes to
##  global variables are thrown away when the function finishes or times
##  out. The return value of <A>func</A> is passed back to the current GAP
##  session via <C>IO_Pickle</C>. Note that <C>IO_Pickle</C> may not be
##  available for all objects.<P/>
##
##  <C>IO_CallWithTimeout</C> is variadic. Any arguments to it beyond the
##  first two are passed as arguments to <A>func</A>.
##  <C>IO_CallWithTimeoutList</C> in contrast takes exactly three arguments,
##  of which the third is a list (possibly empty) of arguments to pass to
##  <A>func</A>. <P/>
##
##  If the call completes within the allotted time and returns a value
##  <C>res</C>, the result of <C>IO_CallWithTimeout[List]</C> is a list of
##  the form <C>[ true, res ]</C>. <P/>
##
##  If the call completes within the allotted time and returns no value, the
##  result of <C>IO_CallWithTimeout[List]</C> is the list <C>[ true ]</C>.<P/>
##
##  If the call does not complete within the timeout, the result of
##  <C>IO_CallWithTimeout[List]</C> is the list <C>[ false ]</C>. If the
##  call causes GAP to crash or exit, the result is the list <C>[ fail ]</C>. <P/>
##
##  The timer is suspended during execution of a break loop and abandoned when
##  you quit from a break loop.<P/>
##
##  The limit <A>timeout</A> is specified as a record. At present the
##  following components are recognised <C>nanoseconds</C>,
##  <C>microseconds</C>, <C>milliseconds</C>, <C>seconds</C>, <C>minutes</C>,
##  <C>hours</C>, <C>days</C> and <C>weeks</C>. Any of these components which
##  is present should be bound to a positive integer, rational or float and
##  the times represented are totalled to give the actual timeout. As a
##  shorthand, a single positive integers may be supplied, and is taken as a
##  number of microseconds. Further components are permitted and ignored, to
##  allow for future functionality.<P/>
##
##  The precision of the timeouts is not guaranteed, and there is a system
##  dependent upper limit on the timeout which is typically about 8 years on
##  32 bit systems and about 30 billion years on 64 bit systems. Timeouts
##  longer than this will be reduced to this limit.<P/>
##  </Description>
##  </ManSection>
##  <#/GAPDoc>

DeclareGlobalFunction("IO_CallWithTimeout");
DeclareGlobalFunction("IO_CallWithTimeoutList");
