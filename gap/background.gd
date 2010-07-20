#############################################################################
##
##  background.gd               GAP 4 package IO                    
##                                                           Max Neunhoeffer
##
##  Copyright (C) 2006-2010 by Max Neunhoeffer
##  This file is free software, see license information at the end.
##
##  This file contains declarations for background processes using fork.
##

# The types for background jobs by fork:

BindGlobal("BackgroundJobsFamily", NewFamily("BackgroundJobsFamily"));

DeclareCategory("IsBackgroundJob", 
                IsComponentObjectRep and IsAttributeStoringRep);
DeclareRepresentation("IsBackgroundJobByFork", IsBackgroundJob,
  ["pid", "towrite", "toread", "result"]);

BindGlobal("BGJobByForkType", 
           NewType(BackgroundJobsFamily, IsBackgroundJobByFork));


# The constructor:

DeclareOperation("BackgroundJobByFork", [IsFunction, IsList]);
DeclareOperation("BackgroundJobByFork", [IsFunction, IsList, IsRecord]);
DeclareGlobalVariable("BackGroundJobByForkOptions");
DeclareGlobalFunction("BackgroundJobByForkChild");


# The operations/attributes/properties:

DeclareOperation("IsIdle", [IsBackgroundJob]);
DeclareOperation("HasTerminated", [IsBackgroundJob]);
DeclareOperation("WaitUntilIdle", [IsBackgroundJob]);
DeclareOperation("WaitUntilTerminated", [IsBackgroundJob]);
DeclareOperation("Kill", [IsBackgroundJob]);
DeclareOperation("GetResult", [IsBackgroundJob]);
DeclareOperation("SendArguments", [IsBackgroundJob, IsList]);


# Parallel skeletons:

DeclareOperation( "ParMapReduceByFork",
  [IsList, IsFunction, IsFunction, IsRecord]);
# Arguments are:
#   list to work on
#   map function
#   reduce function (taking two arguments)
#   options record

DeclareOperation( "ParTakeFirstResultByFork",
  [IsList, IsList, IsRecord]);
# Arguments are:
#   list of job functions
#   list of argument lists
#   options record

DeclareOperation( "ParDoByFork",
  [IsList, IsList, IsRecord]);
# Arguments are:
#   list of job functions
#   list of argument lists
#   options record

DeclareOperation( "ParMakeWorkersByFork",
  [IsList, IsList, IsRecord]);
# Arguments are:
#   list of worker functions
#   list of initial argument lists
#   options record
#
# This creates a new object of type "IsWorkersByFork", planned operations:
#   DeclareOperation("Kill", [IsWorkersByFork]);
#   DeclareOperation("SendWork", [IsWorkersByFork, IsList]);
#   DeclareOperation("IsIdle", [IsWorkersByFork]);
#   DeclareOperation("AreAllIdle", [IsWorkersByFork]);


##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; version 2 of the License.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
##
