(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 1995-2003 Juancarlo Anez, Caracas, Venezuela.              *
 * All rights reserved.                                                     *
 *                                                                          *
 * This library is free software; you can redistribute it and/or            *
 * modify it under the terms of the GNU Lesser General Public               *
 * License as published by the Free Software Foundation; either             *
 * version 2.1 of the License, or (at your option) any later version.       *
 *                                                                          *
 * This library is distributed in the hope that it will be useful,          *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 * Lesser General Public License for more details.                          *
 *                                                                          *
 * You should have received a copy of the GNU Lesser General Public         *
 * License along with this library; if not, write to the Free Software      *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA *
 ****************************************************************************)
{
    @brief Collections: A Delphi port of the Java Collections library.

    @author Juancarlo Añez
    @version $Revision: 706 $
}
unit JALAlgorithms;
interface
uses
   JALCollections;

const
  rcs_id :string = '@(#)$Id: JALAlgorithms.pas 706 2003-05-14 22:13:46Z hippoman $';

type
   recurse_t = (rt_donotrecurse, rt_recurse);

   IUnaryFunction = interface
   ['{BBFBE12C-F88F-4C6A-946E-0E049FFC712E}']
      function run( obj: IUnknown ): IUnknown;
   end;

   IBinaryFunction = interface
   ['{9082D051-94F0-4008-86B2-F9DC92EA01CA}']
      function run( obj1, obj2: IUnknown ): IUnknown;
   end;

function forEach(coll :ICollection; func :IUnaryFunction) :IUnaryFunction; overload;
function inject( coll :ICollection; obj: IUnknown; func: IBinaryFunction ): IUnknown; overload;

function count( coll :ICollection; recurse :recurse_t = rt_donotrecurse) :Integer; overload;
function count( map  :IMap; recurse :recurse_t = rt_donotrecurse) :Integer; overload;


implementation

function forEach(coll :ICollection; func :IUnaryFunction) :IUnaryFunction; overload;
var
  i :IIterator;
begin
   i := coll.iterator;
   while i.hasNext do
       func.run(i.next);
   result := func
end;

function inject( coll :ICollection; obj: IUnknown; func: IBinaryFunction ): IUnknown; overload;
var
  i :IIterator;
begin
   i := coll.iterator;
   while i.hasNext do
       obj := func.run(obj, i.next);
   result := obj
end;

function count( coll :ICollection; recurse :recurse_t = rt_donotrecurse) :Integer;
var
  i   :IIterator;
  obj :IUnknown;
  sub :ICollection;
begin
   result := 0;
   i := coll.iterator;
   while i.hasNext do begin
       obj := i.next;
       if recurse = rt_donotrecurse then
          inc(result)
       else begin
           obj.queryInterface(ICollection, sub);
           if sub <> nil then
              inc(result, count(sub, recurse))
           else
              inc(result, 1);
       end
   end
end;

function count( map  :IMap; recurse :recurse_t = rt_donotrecurse) :Integer; overload;
var
  i   :IIterator;
  obj :IUnknown;
  sub :IMap;
begin
   result := 0;
   i := map.values.iterator;
   while i.hasNext do begin
       obj := i.next;
       if recurse = rt_donotrecurse then
          inc(result)
       else begin
           obj.queryInterface(IMap, sub);
           if sub <> nil then
              inc(result, count(sub, recurse))
           else
              inc(result, 1);
       end
   end
end;


end.
