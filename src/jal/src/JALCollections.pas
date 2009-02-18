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
    @brief A Delphi port of the Java Collections library.

    @author Juancarlo Añez
    @version $Revision: 725 $
}

unit JALCollections;
interface
uses
  SysUtils,
  Classes,
  Math;

const
  rcs_id :string = '@(#)$Id: JALCollections.pas 725 2003-06-05 03:39:01Z barnson $';

const
    RED   = false;
    BLACK = true;

type
{$IFDEF VER130}
  IInterface = IUnknown;
{$ENDIF}
  CollectionException = class(Exception)
     constructor create;              overload;
     constructor create(msg :string); overload;
  end;

  InternalError                   = class(CollectionException);
  IllegalArgumentException        = class(CollectionException);
  NoSuchElementException          = class(CollectionException);
  IllegalStateException           = class(CollectionException);
  ConcurrentModificationException = class(CollectionException);
  CloneNotSupportedException      = class(CollectionException);
  NotImplementedException         = class(CollectionException);
  UnsupportedOperationException   = class(CollectionException);

//////////////////////////////////////////////////////////////
// INTERFACES
  IObject    = interface(IUnknown)
     ['{A1630E80-D635-11D2-992E-00207813339E}']
     function equals(o :IUnknown) :Boolean;
     function hash :Longint;
     function toString :string;
     function instanceOf(const iid :TGUID) :boolean;
  end;

  IDelphiObject = interface(IObject)
  ['{6B899B96-3315-40E1-B4AF-A287C84775DB}']
     function obj :TObject;
  end;

  IComparable = interface(IObject)
  ['{9A07D08A-52A3-43D9-93CF-B79F403584CA}']
     function compareTo(other :IUnknown) :Integer;
  end;

  IReference = interface(IObject)
     ['{A1630E81-D635-11D2-992E-00207813339E}']
     function referent: TObject;
  end;

  IString = interface(IComparable)
     ['{D7732440-D718-11D2-992E-00207813339E}']
     function toString :string;
  end;

  IInteger = interface(IComparable)
     ['{D7732440-D718-11D2-992E-00207813339E}']
     function intValue :integer;
  end;

  ILongint = interface(IComparable)
     ['{715DF8E3-9925-11D3-992E-00207813339E}']
     function longValue :longint;
  end;

  IDouble = interface(IComparable)
     ['{715DF8E4-9925-11D3-992E-00207813339E}']
     function doubleValue :double;
  end;

  IBoolean = interface(IComparable)
     ['{E77E1067-A0E5-4840-BA7F-1F12D7EF3E56}']
     function boolValue :boolean;
  end;

  INumber = interface(IComparable)
     ['{8CEEC826-40C9-4775-A32A-D528B75A6289}']
     function intValue :integer;
     function longValue :longint;
     function doubleValue :double;
  end;

  IVariant = interface(INumber)
    ['{78C9B810-B49F-44C6-98B1-D9404BB7F9EB}']
    function boolValue :boolean;
  end;

  IIterator = interface(IObject)
      ['{CB35D502-D656-11D2-992E-00207813339E}']
      function  hasNext :Boolean;
      function  next    :IUnknown;
      function  nextStr :string;
      procedure remove;
  end;

  ICollection = interface(IObject)
    ['{A1630E82-D635-11D2-992E-00207813339E}']

    function  add(item:IUnknown):boolean;       overload;
    function  remove(item :IUnknown):IUnknown;  overload;
    function  has(item :IUnknown) :Boolean;     overload;
    function  get(key:IUnknown):IUnknown;       overload;
    procedure addAll(other :ICollection);

    function  isEmpty :boolean;
    function  isFull  :boolean;
    function  size    :Integer;
    procedure clear;

    function  iterator :IIterator;

    (*!!!
    function  hasAll(c :ICollection):boolean;
    procedure removeAll(c :ICollection);
    *)

    function  add(item :string)    :boolean;     overload;
    function  remove(item :string) :IUnknown;    overload;
    function  has(item :string)    :boolean;     overload;
    function  get(key:string)      :IUnknown;    overload;
    function  getStr(key:Iunknown) :string;      overload;
    function  getStr(key:string)   :string;      overload;
  end;

  IList = interface(ICollection)
    ['{CB35D500-D656-11D2-992E-00207813339E}']
    function  at(index :Integer):IUnknown;
    function  indexOf(obj :IUnknown; from :integer = 0) :integer;
    function  lastIndexOf(obj :IUnknown) :integer;
    function  remove(index :integer):IUnknown;    overload;
    procedure put(index :Integer; item :IUnknown);
    procedure insert(index :Integer; item :IUnknown); overload;
    procedure insert(index :Integer; item :string);   overload;

    procedure move(item, pos :integer);  overload;
    procedure move(item :IUnknown; pos :integer);  overload;

    function  first :IUnknown;
    function  last :IUnknown;

    property  item[i :integer] : IUnknown read at write put; default;

    (*
    function  add(index :Integer; item :IUnknown):boolean;
    function  sublist(fromIndex, toIndex :Integer):IList;
    *)
  end;

  IListIterator = interface(IIterator)
    ['{CB35D501-D656-11D2-992E-00207813339E}']
  end;

  IEntry = interface(IObject)
  ['{2EC71804-EE73-4829-B1EC-144D7BEA6B3B}']
     function  getValue :IUnknown;
     procedure setValue(value :IUnknown);
     property  value :IUnknown read getValue write setValue;
  end;

  IListEntry = interface(IEntry)
  ['{ADBE483F-34ED-4951-AF6A-E66059A0B6D6}']
     function  disconnect :IListEntry;

     function  getPrev :IListEntry;
     procedure setPrev (value :IListEntry);

     function  getNext :IListEntry;
     procedure setNext (value :IListEntry);

     property  next  :IListEntry  read getNext  write setNext;
     property  prev  :IListEntry  read getPrev  write setPrev;
  end;

  ISet = interface(ICollection)
   ['{A1630E83-D635-11D2-992E-00207813339E}']
  end;

  IComparator = interface(IObject)
  ['{0B1F1BEC-F8E0-4352-AA61-D305E0B25E78}']
    function compare(o1, o2 :IUnknown) :Integer;
    function equals(obj :IUnknown) :boolean;
  end;

  ISortedSet = interface(ISet)
  ['{C1072944-E99D-4265-AA6E-E5365870B17F}']
    function comparator :IComparator;
    //function subSet(fromElement, toElement :IUnknown) :ISortedSet;
    //function headSet(toElement :IUnknown)   :ISortedSet;
    //function tailSet(fromElement :IUnknown) :ISortedSet;
    function first :IUnknown;
    function last :IUnknown;
  end;

  IMapEntry = interface(IEntry)
  ['{D7732441-D718-11D2-992E-00207813339E}']
     function  key   :IUnknown;
  end;

  IMap = interface(IObject)
  ['{D7732442-D718-11D2-992E-00207813339E}']
      function   put(key, value:IUnknown):IUnknown;      overload;
      function   get(key:IUnknown):IUnknown;             overload;
      function   remove(key :IUnknown):IUnknown;         overload;
      function   has(key :IUnknown) :boolean;            overload;
      function   getEntry(key:IUnknown):IMapEntry;       overload;

      function   isEmpty :boolean;
      function   isFull  :boolean;
      function   size    :Integer;
      procedure  clear;

      function   keys     :IIterator;
      function   entrySet   :ISet;
      function   keySet   :ISet;
      function   values   :ICollection;
      function   entries :IIterator;

      function   put(key, value:string):IUnknown;      overload;
      function   get(key:string):IUnknown;             overload;
      function   remove(key :string):IUnknown;         overload;
      function   has(key :string) :boolean;            overload;
      function   getEntry(key:string):IMapEntry;       overload;

      function  getStr(key:Iunknown) :string;    overload;
      function  getStr(key:string)   :string;    overload;

      function  get(key :integer) :IUnknown;                 overload;
      function  put(key :integer; value :IUnknown):IUnknown; overload;
      function  put(key, value :integer):IUnknown;           overload;
  end;

  ISortedMap = interface(IMap)
  ['{73D6D45B-74E0-4447-9E9B-A460DD646093}']
    function comparator :IComparator;
    //!!!function subMap(fromKey, toKey :IUnknown) :ISortedMap;
    //!!!function headMap(toKey :IUnknown)         :ISortedMap;
    //!!!function tailMap(fromKey :IUnknown)       :ISortedMap;
    function firstKey :IUnknown;
    function lastKey  :IUnknown;
  end;

  ITreeEntry = interface(IMapEntry)
  ['{540DF438-731F-4B67-AB01-BCA43D8CF8F8}']
    //function key     :IUnknown;
    function getLeft    :ITreeEntry;
    function getRight   :ITreeEntry;
    function getParent  :ITreeEntry;

    procedure setLeft(t :ITreeEntry);
    procedure setRight(t :ITreeEntry);
    procedure setParent(t :ITreeEntry);

    function isBlack :boolean;
    function isRed   :boolean;

    procedure setRed;
    procedure setBlack;
    function  getColor :boolean;
    procedure setColor(color :boolean);

    property left    :ITreeEntry read getLeft   write setLeft;
    property right   :ITreeEntry read getRight  write setRight;
    property parent  :ITreeEntry read getParent write setParent;
    property color   :boolean    read getColor  write setColor;
  end;

  IStack = interface(IObject)
  ['{9E6706E0-3B9E-11D3-992E-00207813339E}']
     function  push(item :IUnknown) :integer;
     function  pop:IUnknown;
     function  squash :IUnknown;

     function  top      :IUnknown;
     function  bottom   :IUnknown;
     function  size    :integer;
     function  isEmpty  :boolean;
     function  isFull   :boolean;

     function  indexOf(Item :IUnknown) :Integer;
     function  has(Item :IUnknown) :Boolean;
     function  remove(item :IUnknown):IUnknown;

     function  items :IList;

     procedure clear;
  end;

//////////////////////////////////////////////////////////////
// OBJECTS

  TAbstractObject = class(TInterfacedObject, IObject, IDelphiObject)
     function equals(o :IUnknown) :boolean; virtual;
     function hash :longint;                virtual;
     function obj :TObject;
     function referent: TObject;            virtual;
     function toString :string;             virtual;
     function clone    :IUnknown;           virtual;
     function instanceOf(const iid :TGUID) :boolean;   virtual;
  end;

  TReference = class(TAbstractObject, IVariant, IReference, IComparable)
  protected
     _obj :TObject;

     constructor create(obj :TObject);
  public
    function referent: TObject;             override;
    function equals(o :IUnknown) :boolean;  override;
    function hash :longint;                 override;
    function compareTo(other :IUnknown) :Integer; virtual;

    function intValue    :integer;
    function longValue   :longint;
    function doubleValue :double;
    function boolValue :boolean;
  end;

  TOwnerReference = class(TReference)
  public
     destructor Destroy; override;
  end;

  TStrReference = class(TAbstractObject, IVariant, IComparable, IString)
    _str  :string;
    _hash :longint;

    constructor create(const str :string);

    function equals(o :IUnknown) :boolean;        override;
    function hash :longint;                       override;
    function toString :string;                    override;
    function compareTo(other :IUnknown) :Integer; virtual;

    function intValue    :integer;
    function longValue   :longint;
    function doubleValue :double;
    function boolValue :boolean;
  end;

  TIntReference = class(TAbstractObject, IComparable, IVariant, INumber, IInteger, ILongint, IDouble)
    _int  :integer;

    constructor create(const int :integer);

    function equals(o :IUnknown) :boolean; override;
    function hash :longint;               override;
    function toString :string;            override;
    function compareTo(other :IUnknown) :Integer; virtual;

    function intValue    :integer;
    function longValue   :longint;
    function doubleValue :double;
    function boolValue :boolean;
  end;

  TLongReference = class(TAbstractObject, IComparable, IVariant, INumber, IInteger, ILongint, IDouble)
    _long  :longint;

    constructor create(const long :longint);

    function equals(o :IUnknown) :boolean; override;
    function hash :longint;                override;
    function toString :string;             override;
    function compareTo(other :IUnknown) :Integer; virtual;

    function intValue    :integer;
    function longValue   :longint;
    function doubleValue :double;
    function boolValue :boolean;
  end;

  TDoubleReference = class(TAbstractObject, IComparable, INumber, IInteger, ILongint, IDouble)
    _dbl  :double;

    constructor create(const dbl :double);

    function equals(o :IUnknown) :boolean; override;
    function hash :longint;               override;
    function toString :string;            override;
    function compareTo(other :IUnknown) :Integer; virtual;

    function intValue    :integer;
    function longValue   :longint;
    function doubleValue :double;
    function boolValue :boolean;
  end;

  TBoolReference = class(TAbstractObject, IComparable, IVariant, INumber, IInteger, ILongint, IDouble)
    _bol  :boolean;

    constructor create(const bol :boolean);

    function equals(o :IUnknown) :boolean; override;
    function hash :longint;               override;
    function toString :string;            override;
    function compareTo(other :IUnknown) :Integer; virtual;

    function intValue    :integer;
    function longValue   :longint;
    function doubleValue :double;
    function boolValue :boolean;
  end;






  TAbstractIterator = class(TAbstractObject, IIterator)
      function  hasNext :boolean;   virtual; abstract;
      function  next    :IUnknown;  virtual; abstract;
      procedure remove;             virtual; abstract;

      function  nextStr :string;    virtual;
  end;

  TAbstractCollection = class(TAbstractObject, ICollection)
    function  add(item:IUnknown):boolean;        overload; virtual;
    function  remove(item :IUnknown):IUnknown;   overload; virtual;
    function  has(item :IUnknown) :boolean;      overload; virtual;
    function  get(key:IUnknown):IUnknown;        overload; virtual;
    procedure addAll(other :ICollection);        virtual;

    function  first   :IUnknown;                     virtual;
    function  last    :IUnknown;                     virtual;

    function  isEmpty :boolean;    virtual;
    function  isFull  :boolean;    virtual;
    function  size    :Integer;    virtual; abstract;
    procedure clear;               virtual;

    function  iterator :IIterator; virtual; abstract;

    function  add(item :string)    :boolean;   overload;
    function  remove(item :string) :IUnknown;  overload;
    function  has(item :string)    :boolean;   overload;
    function  get(key:string)      :IUnknown;  overload;
    function  getStr(key:Iunknown) :string;    overload;
    function  getStr(key:string)   :string;    overload;

    function toString :string; override;
  end;

  TAbstractList = class(TAbstractCollection, IList)
    function equals(o :IUnknown) :boolean;       override;
    function hash :longint;                      override;
    function first :IUnknown;                    override;
    function last  :IUnknown;                    override;
    function at(index :Integer):IUnknown;        virtual;
    function remove(index :integer):IUnknown;    overload; virtual;
    function indexOf(obj :IUnknown; from :integer = 0) :integer; virtual;
    function lastIndexOf(obj :IUnknown) :integer;                virtual;

    procedure put(index :Integer; item :IUnknown); overload; virtual; abstract;
    procedure insert(index :Integer; item :IUnknown); overload; virtual; abstract;
    procedure insert(index :Integer; item :string);   overload;

    procedure move(frompos, topos :integer);  overload;
    procedure move(item :IUnknown; pos :integer);  overload;
  end;

  TAbstractListIterator = class(TAbstractIterator, IListIterator, IIterator)
  protected
      _list    :IList;
      constructor create(list :IList);
  end;

  TLinkedList = class(TAbstractList, IList)
    constructor create;
    destructor  Destroy; override;

    function    at(index :Integer):IUnknown;        override;
    function    add(item:IUnknown):boolean;      override;
    function    remove(item :IUnknown):IUnknown; override;
    function    remove(index :Integer):IUnknown; override;
    function    size :Integer;                   override;
    function    isEmpty :boolean;                override;
    procedure   clear;                           override;
    function    iterator :IIterator;             override;
    function    first :IUnknown;                 override;
    function    last  :IUnknown;                 override;

    procedure put(index :Integer; item :IUnknown); overload; override;
    procedure insert(index :Integer; item :IUnknown); override;
  protected
    _head  :IListEntry;
    _size :Integer;

    function entryAt(index :integer):IListEntry;
    procedure removeEntry(e :IListEntry);
    function _insert(o :IUnknown; before :IListEntry):IListEntry;
  end;

  TEntry = class(TAbstractObject, IEntry)
  protected
     _value :IUnknown;
  public
     constructor create(avalue :IUnknown); overload;
     constructor create;                  overload;
     function getValue :IUnknown;
     procedure setValue(value :IUnknown);
  end;

  TListEntry = class(TEntry, IListEntry)
     destructor  Destroy;                                 override;
  protected
     _prev  :IListEntry;
     _next  :IListEntry;

     constructor create(avalue :IUnknown; before :IListEntry); overload;
     constructor create;                                  overload;

     function disconnect :IListEntry;

     function getPrev :IListEntry;
     procedure setPrev (value :IListEntry);

     function getNext :IListEntry;
     procedure setNext (value :IListEntry);
  end;

  TLinkedListIterator = class(TAbstractListIterator, IListIterator, IIterator)
      function  hasNext :boolean;  override;
      function  next    :IUnknown;  override;
      procedure remove;            override;
  protected
      _current :IListEntry;
      _list    :TLinkedList;
      constructor create(list :TLinkedList; pos :IListEntry);
  end;

  TArrayList = class(TAbstractList, IList)
    constructor create;                              overload;
    constructor create(Capacity :Integer);           overload;
    destructor  destroy; override;
    function    add(item:IUnknown):boolean;          override;
    function    remove(item :IUnknown):IUnknown;     overload; override;
    function    remove(index :integer):IUnknown;     overload; override;
    function    size :Integer;                       override;
    procedure   clear;                               override;
    function    iterator :IIterator;                 override;
    function    at(index :Integer):IUnknown;         override;
    procedure   put(index :Integer; item :IUnknown); overload; override;
    procedure   insert(index :Integer; item :IUnknown); override;

    procedure setCapacity(value :integer);  virtual;
    function  getCapacity :integer;         virtual;

    property capacity :integer read getCapacity write setCapacity;
  protected
    _list  :array of IUnknown;
    _count :Integer;

    procedure grow;
    procedure shrink;

  end;

  TArrayListIterator = class(TAbstractListIterator, IListIterator, IIterator)
      function  hasNext :boolean;  override;
      function  next    :IUnknown;  override;
      procedure remove;            override;
  protected
      _current :integer;
      _last    :integer;
      constructor create(list :TArrayList; pos :integer);
  end;

  TIListArray = array of IList;
  THashListClass = TArrayList;

  TAbstractSet = class(TAbstractCollection, ISet)
    function  equals(o :IUnknown) :boolean;  override;
    function  hash :longint;                override;
  end;

  THashSet = class(TAbstractSet, ISet)
  protected
    _items     : TIListArray;
    _factor    :single;
    _size      :Integer;
  public
    constructor create(aLimit :Integer; factor :single); overload;
    constructor create(aLimit :Integer); overload;
    constructor create; overload;

    destructor  Destroy; override;

    function   add(item:IUnknown):boolean;      override;
    function   remove(item :IUnknown):IUnknown;  override;
    function   has(item :IUnknown) :boolean;    override;
    function   get(key:IUnknown):IUnknown;       override;
    function   size :Integer;                  override;
    procedure  clear;                          override;
    function   Iterator :IIterator;            override;

  protected
    function  search(item :IUnknown; var index:Integer):boolean; virtual;
    function  hashIndex(item :IUnknown):Integer;                 virtual;

    function  limit :Integer;                                   virtual;
    procedure grow;                                             virtual;
  end;

  TMapEntry = class(TAbstractObject, IMapEntry)
  protected
     _key   :IUnknown;
     _value :IUnknown;
  public
     constructor create(key, value :IUnknown);

     function  key   :IUnknown;
     function  getValue :IUnknown;
     procedure setValue(value :IUnknown);

     function  equals(o :IUnknown) :boolean; override;
     function  hash :longint;                  override;
  end;

  TAbstractMap = class(TAbstractObject, IMap)
  public
      function  put(key, value:IUnknown):IUnknown;    overload; virtual; abstract;
      function  get(key:IUnknown):IUnknown;           overload; virtual;
      function  remove(key :IUnknown):IUnknown;       overload; virtual; abstract;
      function  has(key :IUnknown) :boolean;          overload; virtual;
      procedure putAll(other :IMap);                  overload; virtual;

      function  isEmpty :boolean;                     virtual;
      function  isFull  :boolean;                     virtual;
      function  size    :Integer;                     virtual; abstract;
      procedure clear;                                virtual;

      function  keys     :IIterator;                  virtual;
      function  keySet   :ISet;                       virtual;
      function  values   :ICollection;                virtual;
      function  entrySet :ISet;                       virtual;

      function  containsKey(key :IUnknown) :boolean;       virtual;
      function  containsValue(value :IUnknown) :boolean;   virtual;

      function   put(key, value:string):IUnknown;      overload;
      function   get(key:string):IUnknown;             overload;
      function   remove(key :string):IUnknown;         overload;
      function   has(key :string) :boolean;            overload;

      function  getStr(key:Iunknown) :string;    overload;
      function  getStr(key:string)   :string;    overload;

      function  getEntry(key:IUnknown):IMapEntry;   overload; virtual; abstract;
      function  getEntry(key:string):IMapEntry;     overload; virtual;

      function  get(key :integer) :IUnknown;                 overload; virtual;
      function  put(key :integer; value :IUnknown):IUnknown; overload; virtual;
      function  put(key, value :integer):IUnknown;           overload; virtual;

      function  entries :IIterator;  virtual; abstract;
      procedure removeEntry(e :IMapEntry); virtual; abstract;

      class function key(e :IMapEntry) :IUnknown;
      class function valEquals(o1, o2 :IUnknown) :boolean;
  protected
      _modCount  :Integer;

      constructor create;
      function entry(key, value: IUnknown): IMapEntry;  overload; virtual;
      function entry(key :IUnknown): IMapEntry;         overload;

  private
    _keySet   :ISet;
    _entrySet :ISet;
    _values   :ICollection;
  end;

  TMapIterator = class(TAbstractIterator, IIterator)
      _base :IIterator;
      constructor create(base :IIterator);
      function  hasNext :boolean;  override;
      function  next    :IUnknown;  override;
      procedure remove;            override;
  end;

  TMapKeysIterator = class(TMapIterator, IIterator)
      function  next    :IUnknown;  override;
  end;

  TMapValuesIterator = class(TMapIterator, IIterator)
      function  next    :IUnknown;  override;
  end;


  THashMap = class(TAbstractMap)
  protected
    _set :ISet;
  public
    constructor create(aLimit :Integer; factor :single); overload;
    constructor create(aLimit :Integer); overload;
    constructor create; overload;

    function put(key, value: IUnknown): IUnknown; override;
    function remove(key :IUnknown):IUnknown;      override;
    function size     :Integer;                   override;
    function entrySet :ISet;                      override;

    procedure removeEntry(e :IMapEntry);          override;

    function  getEntry(key:IUnknown):IMapEntry;   override;
    function  entries :IIterator;           override;
  end;

  THashSetIterator = class(TAbstractIterator, IIterator)
    _holder    :ISet;
    _owner     :THashSet;
    _index     :Integer;
    _iter      :IIterator;

    constructor create(owner :THashSet);

    function  hasNext :boolean;     override;
    function  next    :IUnknown;    override;
    procedure remove;               override;

    function  nextIndex(i :integer) :integer;
    procedure gotoNext;
  end;

  TTreeEntry = class(TMapEntry, ITreeEntry, IComparable)
  protected
    _left,
    _right  :ITreeEntry;
    _parent :Pointer;
    _color  :boolean;
  public
    constructor create(key, value :IUnknown; parent :ITreeEntry);

    function getLeft    :ITreeEntry;
    function getRight   :ITreeEntry;
    function getParent  :ITreeEntry;

    procedure setLeft(t :ITreeEntry);
    procedure setRight(t :ITreeEntry);
    procedure setParent(t :ITreeEntry);

    function isBlack :boolean;
    function isRed   :boolean;

    procedure setRed;
    procedure setBlack;
    function  getColor :boolean;
    procedure setColor(color :boolean);

    function compareTo(other :IUnknown) :Integer;
  end;

  TTreeMap = class(TAbstractMap, ISortedMap)
    _comparator :IComparator;
    _root       :ITreeEntry;
    _size       :Integer;

  public
    constructor create;                    overload;
    constructor create(c :IComparator);    overload;
    constructor create(other :IMap);       overload;
    constructor create(other :ISortedMap); overload;

    destructor destroy; override;

    // Query Operations
    function  size :integer;              override;
    function  comparator :IComparator;    virtual;
    function  firstKey :IUnknown;          virtual;
    function  lastKey :IUnknown;           virtual;
    procedure putAll(other :IMap);        override;

    function  put(key, newValue :IUnknown) :IUnknown;   override;
    function  remove(item :IUnknown) :IUnknown;         override;
    procedure clear;                                    override;
    function  clone :IUnknown;                          override;

    function containsKey(key :IUnknown) :boolean;       override;
    function containsValue(value :IUnknown) :boolean;   override;

    function entries :IIterator;     override;
    function getEntry(key :IUnknown) :IMapEntry;   override;
    procedure removeEntry(e :IMapEntry);           override;
    function firstEntry :IMapEntry;                virtual;
    function lastEntry  :IMapEntry;                virtual;


    //function subSet(fromElement, toElement :IUnknown) :ISortedSet;
    //function headSet(toElement :IUnknown)   :ISortedSet;
    //function tailSet(fromElement :IUnknown) :ISortedSet;
  protected
    procedure buildFromSorted( size       :integer;
                               it         :IIterator;
                               str        :IUnknown;
                               defaultVal :IUnknown); overload;
        // throws  java.io.IOException, ClassNotFoundException
    class function buildFromSorted(level,
                                   lo, hi,
                                   redLevel   :integer;
                                   it         :IIterator;
                                   str        :IUnknown;
                                   defaultVal :IUnknown) :ITreeEntry; overload;
    //    throws  java.io.IOException, ClassNotFoundException {
    class function computeRedLevel(sz :integer) :integer;
    class function successor(t :ITreeEntry) :ITreeEntry;
    procedure addAllForTreeSet(aset :ISortedSet; defaultVal :IUnknown);

    class function colorOf(p :ITreeEntry) :boolean;
    class function parentOf(p :ITreeEntry) :ITreeEntry;
    class procedure setColor(p :ITreeEntry; c :boolean);
    class function leftOf(p :ITreeEntry)  :ITreeEntry;
    class function rightOf(p :ITreeEntry) :ITreeEntry;
    procedure rotateLeft(p :ITreeEntry);
    procedure rotateRight(p :ITreeEntry);
    procedure fixAfterInsertion(x :ITreeEntry);
    procedure fixAfterDeletion(x :ITreeEntry);
    procedure swapPosition(x, y :ITreeEntry);

    function compare(k1, k2 :IUnknown) :integer;

  protected
    function getCeilEntry(key :IUnknown) :ITreeEntry;
    function getPrecedingEntry(key :IUnknown) :ITreeEntry;
  private
    procedure incrementSize;
    procedure decrementSize;
    function valueSearchNull(n :ITreeEntry) :boolean;
    function valueSearchNonNull(n :ITreeEntry; value :IUnknown) :boolean;
  end;

  TTreeSet = class(TAbstractSet, ISortedSet)
  protected
    _sset :TTreeMap;
  public
    function    comparator :IComparator;
    constructor create;                    overload;
    constructor create(c :IComparator);    overload;
    constructor create(other :ISet);       overload;
    constructor create(other :ISortedSet); overload;

    function  add(item:IUnknown):boolean;  override;
    function  size :integer;               override;
    function  iterator :IIterator;         override;
  end;

  TMapView = class(TAbstractSet)
  protected
      _myMap :TAbstractMap;
      constructor create(owner :TAbstractMap);
  public
      function  size :integer;                   override;
      procedure clear;                           override;
  end;

  TEntryView = class(TMapView)
  public
      function  iterator :IIterator;             override;
      function  has(o :IUnknown) :boolean;        override;
      function  remove(o :IUnknown):IUnknown;      override;
  end;

  TKeyView = class(TMapView)
  public
      function  iterator :IIterator;            override;
      function  has(o :IUnknown) :boolean;       override;
      function  remove(o :IUnknown):IUnknown;     override;
  end;

  TValueView = class(TMapView)
  public
      function iterator :IIterator;             override;
      function has(o :IUnknown) :boolean;        override;
      function remove(o :IUnknown):IUnknown;      override;
  end;

  TTreeIterator = class(TAbstractIterator, IIterator)
     _myMap            :TTreeMap;
     _expectedModCount :integer;
     _lastReturned     :ITreeEntry;
     _next             :ITreeEntry;
     _firstExcluded    :ITreeEntry;
  protected
     constructor create(aset :TTreeMap); overload;
     constructor create(aset :TTreeMap; first, firstExcluded :ITreeEntry); overload;

  public
     function  hasNext :boolean;    override;
     function  next    :IUnknown;   override;
     procedure remove;              override;
  end;

  TStack = class(TAbstractObject, IStack)
     constructor create(items :IList);

     function  push(item :IUnknown):integer;  virtual;
     function  pop:IUnknown;                  virtual;
     function  squash :IUnknown;              virtual;

     function  top     :IUnknown;     virtual;
     function  bottom  :IUnknown;     virtual;
     function  size   :Integer;       virtual;
     function  isEmpty :boolean;      virtual;
     function  isFull  :boolean;      virtual;

     function  indexOf(Item :IUnknown) :Integer; virtual;
     function  has(Item :IUnknown) :Boolean;     virtual;
     function  remove(item :IUnknown):IUnknown;  virtual;
     function  items :IList;

     procedure clear;                            virtual;
  protected
     _items :IList
  end;

  THeap = class(TStack)
  public
    function  remove(item :IUnknown):IUnknown;    override;
    function  top     :IUnknown;                  override;
    function  bottom  :IUnknown;                  override;
    function  push(item :IUnknown):integer;       override;
    function  pop:IUnknown;                       override;
    function  squash :IUnknown;                   override;
    function  check : boolean;                    virtual;
    function  compare(o1, o2 :IUnknown) :integer; virtual;
  protected
    function  put(i :integer; item :IUnknown):IUnknown;
    function  deheap(i :integer):IUnknown;
    function  decant(j :integer) :integer;
    function  searchdel(item :IUnknown; i :integer):IUnknown;
  end;

  function iown(obj :TObject)  :IReference;
  function iref(obj :TObject)  :IReference;  overload;
  function iref(str :string)   :IString;     overload;
  function iref(int :integer)  :Inumber;     overload;
  function ilong(lng :longint) :INumber;
  function iref(dbl :double)   :INumber;     overload;
  function iref(bol :boolean)  :INumber;     overload;

  function compare(i1, i2 :longint)      :integer;  overload;
  function compare(k1, k2 :IUnknown)     :integer;  overload;
  function equal(item1, item2: IUnknown) :boolean;
  function hashOf(item: IUnknown)        :longint;  overload;
  function hashOf(item: TObject)         :longint;  overload;
  function stringOf(item: IUnknown)      :string;   overload;
  function stringOf(item: TObject)       :string;   overload;
  function intOf(item: IUnknown)         :integer;  overload;

implementation

const
  inull :IUnknown = nil;

function iref(obj :TObject):IReference;
begin
   result := TReference.create(obj)
end;

function iown(obj :TObject):IReference;
begin
   result := TOwnerReference.create(obj)
end;

function iref(str :string):IString;
begin
   result := TStrReference.create(str)
end;

function iref(int :integer) :INumber;
begin
   result := TIntReference.create(int)
end;

function ilong(lng :longint) :INumber;
begin
   result := TLongReference.create(lng)
end;


function iref(dbl :double) :INumber;
begin
   result := TDoubleReference.create(dbl)
end;

function iref(bol :boolean)  :INumber;
begin
   result := TBoolReference.create(bol);
end;

function compare(i1, i2: longint): integer;
begin
   if i1 = i2 then
      result := 0
   else if i1 > i2 then
      result := 1
   else
      result := -1
end;

function compare(k1, k2 :IUnknown) :integer;
var
   c :IComparable;
begin
  if k1 = k2 then
    result := 0
  else if k1 = nil then
    result := -1
  else if k2 = nil then
    result := 1
  else if k1.queryInterface(IComparable, c) = 0 then
    result := c.compareTo(k2)
  else if k2.queryInterface(IComparable, c) = 0 then
    result := - c.compareTo(k1)
  else
    raise UnsupportedOperationException.create
end;

function hashOf(item: IUnknown): integer;
var
  o :IObject;
begin
  if item = nil then
     result := 0
  else begin
     item.queryInterface(IObject, o);
     if o = nil then
        result := longint(item)
     else
        result := o.hash
  end
end;

function hashOf(item: TObject): integer;
begin
     result := longint(item)
end;

function stringOf(item: IUnknown): string;
var
  o :IObject;
begin
  if item = nil then
     result := 'nil'
  else begin
     item.queryInterface(IObject, o);
     if o = nil then
        result := format('interface<%p>', [pointer(item)])
     else
        result := o.toString
  end
end;

function stringOf(item: TObject)   : string;
begin
   if item = nil then
      result := format('%Unknown<%p>', [pointer(item)])
   else
      result := format('%s<%p>', [item.className, pointer(item)])
end;

function intOf(item: IUnknown) :integer;
var
   n :IInteger;
begin
   item.queryInterface(IInteger, n);
   if n = nil then
      raise EInvalidCast.create(stringOf(item));
   result := n.intValue
end;



function equal(item1, item2: IUnknown): boolean;
var
  o1 :IObject;
begin
  if item1 = item2 then
     result := true
  else if item2 = nil then
     result := false
  else if item1 = nil then
     result := false
  else begin
     item1.queryInterface(IObject, o1);
     if o1 = nil then
        result := false
     else
        result := o1.equals(item2)
  end
end;

{ CollectionException}

constructor CollectionException.create;
begin
  inherited create('');
end;

constructor CollectionException.create(msg :string);
begin
  inherited create(msg);
end;

{ TReference }

constructor TReference.create(obj: TObject);
begin
  assert(obj <> nil);
  inherited create;
  self._obj := obj;
end;

function TReference.equals(o :IUnknown) :boolean;
var
  r :IReference;
begin
  if self = Pointer(o) then
     result := true
  else if o = nil then
     result := false
  else begin
      o.queryInterface(IReference, r);
      if r = nil then
         result := false
      else
         result := r.referent = self.referent
  end
end;

function TReference.referent: TObject;
begin
    result := _obj
end;

function TReference.hash: longint;
begin
  result := longint(Pointer(_obj))
end;

function TReference.compareTo(other: IUnknown): Integer;
var
  r :IReference;
begin
  if self = Pointer(other) then
    result := 0
  else begin
    other.queryInterface(IReference, r);
    if r = nil then
       result  := compare(longint(self.referent), longint(pointer(other)))
    else
        result := compare(longint(self.referent), longint(r.referent))
  end
end;

function TReference.boolValue: boolean;
begin
   result := _obj <> nil
end;

function TReference.doubleValue: double;
begin
  result := longValue
end;

function TReference.intValue: integer;
begin
  result := longValue
end;

function TReference.longValue: longint;
begin
  result := Longint(Pointer(_obj))
end;

{ TOwnerReference }

destructor TOwnerReference.Destroy;
begin
  self._obj.Free;
  inherited Destroy
end;

{ TAbstractObject }

function TAbstractObject.equals(o :IUnknown): boolean;
begin
  result := self = Pointer(o)
end;

function TAbstractObject.referent: TObject;
begin
   result := self.obj
end;

function TAbstractObject.hash: longint;
begin
   result := longint(self)
end;

function TAbstractObject.obj: TObject;
begin
   result := self
end;

function TAbstractObject.toString: string;
begin
    result := format('%s <%p>', [self.obj.ClassName, Pointer(self.obj)])
end;

function TAbstractObject.clone    :IUnknown;
begin
   raise CloneNotSupportedException.create
end;

function TAbstractObject.instanceOf(const iid :TGUID) :boolean;
begin
  result := GetInterfaceEntry(iid) <> nil;
end;

{ TStrReference }

function TStrReference.boolValue: boolean;
begin
  result := length(trim(_str)) > 0;
end;

function TStrReference.compareTo(other: IUnknown): Integer;
var
  s :IObject;
begin
  other.queryInterface(IObject, s);
  if s <> nil then
     result := CompareStr(self.toString, s.toString)
  else
      raise UnsupportedOperationException.create
end;

constructor TStrReference.create(const str: string);
begin
  inherited create;
  self._str := str;
end;

function TStrReference.doubleValue: double;
begin
  result := StrToFloat(_str);
end;

function TStrReference.equals(o :IUnknown): boolean;
var
  s :IObject;
begin
  if self = Pointer(o) then
     result := true
  else if o = nil then
     result := false
  else begin
     o.queryInterface(IObject, s);
     result := s.toString = self.toString
  end
end;

function TStrReference.hash: longint;
var
   i :Integer;
begin
  if _hash <> 0 then
    result := _hash
  else begin
    result := 0;
    for i := 1 to length(_str) do
        result := 31*result + ord(_str[i]);
    _hash := result
  end
end;

function TStrReference.intValue: integer;
begin
  result := StrToInt(_str);
end;

function TStrReference.longValue: longint;
begin
  result := StrToInt(_str);
end;

function TStrReference.toString: string;
begin
   result := _str
end;

{ TIntReference }

constructor TIntReference.create(const int: integer);
begin
  inherited create;
  _int := int
end;

function TIntReference.equals(o :IUnknown): boolean;
var
  i :INumber;
begin
  if self = Pointer(o) then
     result := true
  else if o = nil then
     result := false
  else begin
     o.queryInterface(IInteger, i);
     if i = nil then
       result := false
    else
       result := i.intValue = self.intValue
  end
end;

function TIntReference.intValue: integer;
begin
   result := _int
end;

function TIntReference.hash: longint;
begin
   result := intValue
end;

function TIntReference.toString: string;
begin
   result := IntToStr(intValue)
end;

function TIntReference.compareTo(other: IUnknown): Integer;
begin
    result := compare(self.intValue, (other as IInteger).intValue)
end;

function TIntReference.doubleValue: double;
begin
   result := intValue
end;

function TIntReference.longValue: longint;
begin
   result := intValue
end;

function TIntReference.boolValue: boolean;
begin
  result := _int <> 0
end;

{ TDoubleReference }

function TDoubleReference.doubleValue: double;
begin
     result := _dbl
end;

constructor TDoubleReference.create(const dbl: double);
begin
     _dbl := dbl
end;

function TDoubleReference.equals(o :IUnknown): boolean;
var
  d :IDouble;
begin
  if self = Pointer(o) then
     result := true
  else if o = nil then
     result := false
  else begin
      o.queryInterface(IDouble, d);
      if d = nil then
         result := false
      else
         result := d.doubleValue = self.doubleValue
  end
end;

function TDoubleReference.hash: longint;
begin
    result := round(doubleValue)
end;

function TDoubleReference.toString: string;
begin
   result := FloatToStr(doubleValue)
end;

function TDoubleReference.intValue: integer;
begin
     result := longValue
end;

function TDoubleReference.longValue: longint;
begin
   result := round(doubleValue)
end;

function TDoubleReference.compareTo(other: IUnknown): Integer;
var
  f1, f2 :Double;
  d      :IDouble;
begin
   other.queryInterface(IDouble, d);
   if d = nil then
      result := -1
   else begin
        f1 := self.doubleValue;
        f2 := d.doubleValue;
        if f1 = f2 then
           result := 0
        else if f1 > f2 then
           result := 1
        else
           result := -1
   end
end;

function TDoubleReference.boolValue: boolean;
begin
  result := _dbl <> 0.0
end;

{ TLongReference }

function TLongReference.longValue: longint;
begin
   result := _long
end;

constructor TLongReference.create(const long: Integer);
begin
   _long := long
end;

function TLongReference.equals(o :IUnknown): boolean;
var
  l :ILongint;
begin
  if self = Pointer(o) then
     result := true
  else if o = nil then
     result := false
  else begin
      o.queryInterface(ILongint, l);
      if l = nil then
         result := false
      else
         result := l.longValue = self.longValue
  end
end;

function TLongReference.hash: longint;
begin
  result := longValue
end;

function TLongReference.toString: string;
begin
    result := IntToStr(longValue)
end;

function TLongReference.doubleValue: double;
begin
    result := longValue
end;

function TLongReference.intValue: integer;
begin
    result := longValue
end;

function TLongReference.compareTo(other: IUnknown): Integer;
var
  l1, l2 :Longint;
  l      :ILongint;
begin
   other.queryInterface(ILongint, l);
   if l = nil then
      result := -1
   else begin
        l1 := self.longValue;
        l2 := l.longValue;
        if l1 = l2 then
           result := 0
        else if l1 > l2 then
           result := 1
        else
           result := -1
   end
end;

function TLongReference.boolValue: boolean;
begin
   result := _long <> 0
end;

{ TBoolReference }

function TBoolReference.boolValue: boolean;
begin
   result := _bol
end;

function TBoolReference.compareTo(other: IUnknown): Integer;
var
  r :ILongint;
begin
  if (self as IUnknown) = other then
    result := 0
  else begin
    other.queryInterface(IReference, r);
    if r = nil then
       result  := compare(self.longValue, longint(pointer(other)))
    else
       result := compare(self.longValue, r.longValue)
  end
end;


constructor TBoolReference.create(const bol: boolean);
begin
  inherited create;
  _bol := bol;
end;

function TBoolReference.doubleValue: double;
begin
  result := longValue
end;

function TBoolReference.equals(o: IUnknown): boolean;
var
  ib :IBoolean;
begin
  if (self as IUnknown) = o then
     result := true
  else if o.QueryInterface(IBoolean, ib) = 0 then
     result := ib.boolValue = self._bol
  else
     result := false
end;

function TBoolReference.hash: longint;
begin
  result := longValue
end;

function TBoolReference.intValue: integer;
begin
  result := longValue
end;

function TBoolReference.longValue: longint;
begin
  result := Longint(_bol);
end;

function TBoolReference.toString: string;
begin
  if _bol then
     result := 'true'
  else
     result := '';
end;

{ TAbstractCollection }

function TAbstractCollection.has(item: IUnknown): boolean;
begin
  result := get(item) <> nil
end;

procedure TAbstractCollection.clear;
var
  i :IIterator;
begin
  i := iterator;
  while i.hasNext do
      i.remove;
end;

function TAbstractCollection.isEmpty: boolean;
begin
   result := size = 0
end;

function TAbstractCollection.remove(item: IUnknown): IUnknown;
var
  i :IIterator;
  o :IUnknown;
begin
  result := nil;
  i := iterator;
  while i.hasNext do begin
      o := i.next;
      if (o = item) or equal(item, o) then begin
         result := o;
         i.remove;
      end
  end
end;

function TAbstractCollection.isFull: boolean;
begin
  result := false
end;

function TAbstractCollection.get(key: IUnknown): IUnknown;
var
  i :IIterator;
  o :IUnknown;
begin
  result := nil;
  if size > 0 then begin
      i := iterator;
      while i.hasNext do begin
          o := i.next;
          if equal(o, key) then begin
             result := o;
             Break
          end
      end
  end
end;

function TAbstractCollection.first: IUnknown;
begin
  result := iterator.next
end;

function TAbstractCollection.last: IUnknown;
var
  i :IIterator;
begin
  result := nil;
  i := iterator;
  while i.hasNext do
     result := i.next
end;


procedure TAbstractCollection.addAll(other :ICollection);
var
  i :IIterator;
begin
   i := other.iterator;
   while i.hasNext do
      self.add(i.next);
end;

function TAbstractCollection.add(item: IUnknown): boolean;
begin
     raise UnsupportedOperationException.create
end;

function TAbstractCollection.add(item: string): boolean;
begin
     result := add(iref(item))
end;

function TAbstractCollection.get(key: string): IUnknown;
begin
     result := get(iref(key))
end;

function TAbstractCollection.has(item: string): boolean;
begin
     result := has(iref(item))
end;

function TAbstractCollection.remove(item: string): IUnknown;
begin
     result := remove(iref(item))
end;

function TAbstractCollection.getStr(key: Iunknown) :string;
begin
   result := stringOf(get(key))
end;

function TAbstractCollection.getStr(key: string) :string;
begin
   result := stringOf(get(key))
end;

function TAbstractCollection.toString :string;
var
 i :IIterator;
 n :integer;
begin
   result := inherited toString + '[';

   i := self.iterator;
   n := 0;
   if i.hasNext then
     result := result + format('%d:%s', [n,i.nextStr]);
   inc(n);
   while i.hasNext do
   begin
     result := result + format('%d:%s, ', [n,i.nextStr]);
     inc(n);
   end;
   result := result + ']';
end;

{ TAbstractList }

function TAbstractList.at(index: Integer): IUnknown;
var
  i :IIterator;
  n :Integer;
begin
  result := nil;
  i := self.iterator;
  for n := 0 to index-1 do
      if not i.hasNext then
         raise NoSuchelementException.create
      else
         i.next;
  result := i.next
end;

function TAbstractList.indexOf(obj: IUnknown; from :integer): integer;
var
  i :IIterator;
  n :Integer;
begin
  result := -1;
  i := self.iterator;
  n := 0;
  while i.hasNext and (n < from) do
  begin
    i.next;
    inc(n);
  end;

  while i.hasNext and (result < 0) do
  begin
    if equal(obj, i.next) then
      result := n
    else
      inc(n)
  end;
end;

function TAbstractList.lastIndexOf(obj: IUnknown): integer;
var
  i :IIterator;
  n :Integer;
begin
  result := -1;
  i := self.iterator;
  n := 0;
  while i.hasNext do
  begin
    if equal(obj, i.next) then
      result := n;
    inc(n);
  end;
end;

function TAbstractList.equals(o :IUnknown): boolean;
var
  l :IList;
  i, j :IIterator;
begin
  if self = Pointer(o) then
     result := true
  else
     try
        l := o as IList;
        if size <> l.size then
           result := false
        else if hash <> l.hash then
           result := false
        else begin
           i := iterator;
           j := l.iterator;
           while i.hasNext do
              if not equal(i.next, j.next) then begin
                 result := false;
                 Exit
              end;
           result := true
        end
     except
       result := false
     end
end;


function TAbstractList.hash: longint;
var
  i :IIterator;
  o :IUnknown;
begin
  result := 0;
  i := iterator;
  while i.hasNext do begin
      o := i.next;
      result := 31*result;
      if o <> nil then
         Inc(result, hashOf(o));
  end
end;

function TAbstractList.first: IUnknown;
begin
  result := at(0)
end;

function TAbstractList.last: IUnknown;
begin
  result := at(size-1)
end;

function TAbstractList.remove(index: integer): IUnknown;
begin
   result := remove(at(index))
end;

procedure TAbstractList.insert(index :Integer; item :string);
begin
   insert(index, iref(item));
end;

procedure TAbstractList.move(frompos, topos :integer);
var
  item :IUnknown;
begin
  if frompos = topos then
    EXIT;

  item := at(frompos);
  if frompos > topos then
  begin
    remove(frompos);
    insert(topos, item);
  end
  else
  begin                     
    insert(topos+1, item);
    remove(frompos);
  end;
end;

procedure TAbstractList.move(item :IUnknown; pos :integer);
begin
  move(indexOf(item), pos);
end;

{ TAbstractListIterator }

constructor TAbstractListIterator.create(list: IList);
begin
   assert(list <> nil);
   inherited create;
   self._list := list;
end;

{ TLinkedList }

constructor TLinkedList.create;
begin
   inherited create;
   _head := TListEntry.create;
end;

destructor TLinkedList.Destroy;
var
  e :IListEntry;
begin
  _head.prev.next := nil;
  _head.prev := nil;
  e := _head.next;
  while e <> nil do begin
        e.prev.next := nil;
        e.prev := nil;
        e := e.next;
  end;
  _head := nil;
  inherited Destroy
end;

function TLinkedList.add(item: IUnknown): boolean;
begin
  _insert(item, _head);
  result := true;
end;

procedure TLinkedList.clear;
var
  i :IListEntry;
begin
  i := _head;
  repeat
    i.prev := nil;
    i := i.next
  until i = _head;
  _head.next := nil;
  _head := TListEntry.create;
end;

function TLinkedList.Iterator: IIterator;
begin
  result := TLinkedListIterator.create(self, _head)
end;

function TLinkedList.size: Integer;
begin
  result := _size
end;

function TLinkedList._insert(o: IUnknown; before: IListEntry):IListEntry;
begin
   result := TListEntry.create(o, before);
   inc(_size)
end;

procedure TLinkedList.insert(index :Integer; item :IUnknown);
begin
   _insert(item, entryAt(index));
end;

function TLinkedList.isEmpty: boolean;
begin
   result := _head.next = _head
end;

function TLinkedList.remove(item: IUnknown): IUnknown;
var
  i :IIterator;
  o :IUnknown;
begin
  result := nil;
  i := iterator;
  while i.hasNext do begin
      o := i.next;
      if (o = item) or equal(item, o) then
      begin
         result := o;
         i.remove;
      end
  end
end;

function TLinkedList.first: IUnknown;
begin
   if isEmpty then
      raise NoSuchElementException.create('at end of list')
   else
      result := _head.next.value
end;

function TLinkedList.last: IUnknown;
begin
   if isEmpty then
      raise NoSuchElementException.create('at end of list')
   else
      result := _head.prev.value
end;

procedure TLinkedList.put(index: Integer; item: IUnknown);
var
  e :IListEntry;
begin
  e := entryAt(index);
  if e = _head then
    raise NoSuchElementException.Create('invalid index')
  else
    e.value := item;
end;

function TLinkedList.at(index: Integer): IUnknown;
var
  e :IListEntry;
begin
   e := entryAt(index);
   if e = _head then
     raise NoSuchElementException.Create('invalid index')
   else
     result := e.value;
end;

function TLinkedList.entryAt(index: integer): IListEntry;
var
  n :Integer;
begin
  if (index < 0) or (index > self.size) then
    raise IllegalArgumentException.create('index out of bounds');

  result := _head.next;

  n := 0;
  while n < index do
  begin
    result := result.next;
    Inc(n);
    if result = _head then
      break;
  end;
  if (index <> n) then
    raise NoSuchElementException.Create('index out of bounds');
end;

procedure TLinkedList.removeEntry(e: IListEntry);
begin
  if e = _head then
     raise IllegalArgumentException.create;
  e.disconnect
end;

function TLinkedList.remove(index: Integer): IUnknown;
var
   e :IListEntry;
begin
   e := entryAt(index);
   result := e.value;
   e.disconnect;
   dec(_size)
end;

{ TEntry }

constructor TEntry.create(avalue: IUnknown);
begin
   inherited create;
   self._value := avalue;
end;

constructor TEntry.create;
begin
  inherited create;
end;

function TEntry.getValue: IUnknown;
begin
   result := _value
end;

procedure TEntry.setValue(value: IUnknown);
begin
  self._value := value
end;



{ TListEntry }

constructor TListEntry.create(avalue: IUnknown; before: IListEntry);
begin
   inherited create(avalue);

   self._value := avalue;
   self._next  := before;
   self._prev  := before.prev;

   _next.prev  := self;
   _prev.next  := self;
end;

constructor TListEntry.create;
begin
  inherited create;
  self._next := self;
  self._prev := self;
end;

destructor TListEntry.Destroy;
begin
  _next := nil;
  _prev := nil;
  inherited Destroy
end;

function TListEntry.disconnect :IListEntry;
begin
   result := _prev;
   if _next <> nil then
      _next.prev  := _prev;
   if _prev <> nil then
      _prev.next  := _next;
   self._prev := nil;
   self._next := nil;
end;

function TListEntry.getNext: IListEntry;
begin
  result := _next
end;

function TListEntry.getPrev: IListEntry;
begin
  result := _prev
end;

procedure TListEntry.setNext(value: IListEntry);
begin
  _next := value
end;

procedure TListEntry.setPrev(value: IListEntry);
begin
  _prev := value
end;

{ TLinkedListIterator }

constructor TLinkedListIterator.create(list :TLinkedList; pos: IListEntry);
begin
   assert(pos <> nil);
   inherited create(list);
   self._list    := list;
   self._current := pos;
end;

function TLinkedListIterator.hasNext: boolean;
begin
   if _current.next = nil then
      raise ConcurrentModificationException.create('');
   result := _current.next <> _list._head;
end;

function TLinkedListIterator.next: IUnknown;
begin
   if not hasNext then
      raise NoSuchElementException.create('at end of list');
   if _current.next = nil then
      raise ConcurrentModificationException.create('');
   _current := _current.next;

   result   := _current.value;
end;

procedure TLinkedListIterator.remove;
begin
   if (_current = nil)
   or (_current = _list._head)
   or (_current.next = nil)
   then
      raise IllegalStateException.create('');
   _current := _current.disconnect;
   if _current = nil then
      raise ConcurrentModificationException.create('');
   dec(_list._size);
end;

{ TArrayList }

constructor TArrayList.create;
begin
   inherited create;
end;

constructor TArrayList.create(Capacity: Integer);
begin
   self.create;
   self.capacity := capacity;
end;

destructor TArrayList.destroy;
var
  i :Integer;
begin
   for i := low(_list) to high(_list) do
     _list[i] := nil;
   _list := nil;
   inherited destroy;
end;


procedure TArrayList.setCapacity(value :integer);
begin
   setLength(_list, value);
end;

function TArrayList.getCapacity :integer;
begin
   result := length(_list);
end;

procedure TArrayList.grow;
begin
  if size >= capacity then
    capacity := 1 + (capacity*16) div 15;
end;


procedure TArrayList.shrink;
begin
  capacity := size
end;

function TArrayList.add(item: IUnknown): boolean;
begin
  grow;
  _list[size] := item;
  inc(_count);
  result := true;
end;

function TArrayList.at(index: Integer): IUnknown;
begin
  result := _list[index]
end;

procedure TArrayList.clear;
begin
  _count := 0;
  _list := nil;
end;

function TArrayList.iterator: IIterator;
begin
  result := TArrayListIterator.create(self, 0)
end;

function TArrayList.remove(item: IUnknown): IUnknown;
var
  index :Integer;
begin
   result := nil;
   index := indexOf(Item);
   if index >= 0 then
     result := remove(index);
end;

function TArrayList.size: Integer;
begin
   result := _count
end;

function TArrayList.remove(index: integer): IUnknown;
var
  i :integer;
begin
   if (index < 0) or (index >= size) then
      raise IllegalArgumentException.create;
   try
      result := _list[index];
      _list[index] := nil; // important for refcounting
      for i := index+1 to size-1 do
        _list[i-1] := _list[i];
      dec(_count);
   except
     raise NoSuchElementException.create(format('invalid index: %d', [index]))
   end
end;

procedure TArrayList.put(index: Integer; item: IUnknown);
begin
  if (index < 0) or (index > size) then
     raise IllegalArgumentException.create;
  _list[index] := item
end;

procedure TArrayList.insert(index :Integer; item :IUnknown);
var
  i :Integer;
begin
  if (index < 0) or (index > size) then
     raise IllegalArgumentException.create;
  grow;
  for i := index to size-1 do
    _list[i+1] := _list[i];
  _list[index] := item;
  inc(_count);
end;

{ TArrayListIterator }

constructor TArrayListIterator.create(list: TArrayList; pos: integer);
begin
   inherited create(list);
   assert((pos >= 0) and (pos <= list.size));
   self._current := pos;
   _last         := -1;
end;

function TArrayListIterator.hasNext: boolean;
begin
   result := _current < _list.size
end;

function TArrayListIterator.next: IUnknown;
begin
   result := _list.at(_current);
   _last := _current;
   inc(_current)
end;

procedure TArrayListIterator.remove;
begin
   if _last < 0 then
      raise IllegalStateException.create;
   _list.remove(_last);
   if _last < _current then
      dec(_current);
   _last := -1;
end;

{ TAbstractSet }

function TAbstractSet.equals(o :IUnknown): boolean;
var
  s :ISet;
  i :IIterator;
begin
  if self = Pointer(o) then
     result := true
  else 
     try
        s := o as ISet;
        if size <> s.size then
           result := false
        else if hash <> s.hash then
           result := false
        else begin
           i := iterator;
           while i.hasNext do
              if not s.has(i.next) then begin
                 result := false;
                 Exit
              end;
           result := true
        end
     except
       result := false
     end
end;

function TAbstractSet.hash: longint;
var
  i :IIterator;
begin
  result := 0;
  i := iterator;
  while i.hasNext do
        Inc(result, hashOf(i.next));
end;

{ TMapEntry }

constructor TMapEntry.create(key, value: IUnknown);
begin
   inherited create;
   self._key   := key;
   self._value := value
end;

function TMapEntry.equals(o :IUnknown): boolean;
var
   k :IUnknown;
   e :IMapEntry;
begin
   if self = Pointer(o) then
      result := true
   else begin
       o.queryInterface(IMapEntry, e);
       if e = nil then
          result := equal(self.key, o)
       else begin
          k := e.key;
          if k = nil then
             result := self.key = nil
          else
             result := equal(key, k)
       end
   end
end;

function TMapEntry.getValue: IUnknown;
begin
   result := _value
end;

function TMapEntry.hash: longint;
begin
  if _key = nil then
     result := 0
  else
     result := hashOf(_key)
end;

function TMapEntry.key: IUnknown;
begin
   result := _key
end;

procedure TMapEntry.setValue(value: IUnknown);
begin
  _value := value
end;

{ TAbstractMap }

constructor TAbstractMap.create;
begin
  inherited create;
end;

function TAbstractMap.get(key: IUnknown): IUnknown;
var
  e :IMapEntry;
begin
  e := getEntry(key) as IMapEntry;
  if e = nil then
     result := nil
  else
     result := e.value
end;

function TAbstractMap.has(key: IUnknown): boolean;
begin
   result := getEntry(key) <> nil
end;

function TAbstractMap.isFull: boolean;
begin
  result := false;
end;

function TAbstractMap.keys: IIterator;
begin
  result := TMapKeysIterator.create(self.entries)
end;

function TAbstractMap.entrySet :ISet;
begin
    if (_entrySet = nil) then
       _entrySet := TKeyView.create(self);
    result := _entrySet;
end;

function TAbstractMap.keySet :ISet;
begin
    if (_keySet = nil) then
       _keySet := TKeyView.create(self);
    result := _keySet;
end;

function TAbstractMap.values :ICollection;
begin
    if (_values = nil) then
       _values := TValueView.create(self);
    result := _values;
end;

procedure  TAbstractMap.putAll(other :IMap);
var
  i :IIterator;
  o :IUnknown;
begin
  i := other.keys;
  while i.hasNext do begin
     o := i.next;
     self.put(o, other.get(o))
  end
end;

function TAbstractMap.entry(key: IUnknown): IMapEntry;
begin
  result := entry(key, inull)
end;

class function TAbstractMap.key(e :IMapEntry) :IUnknown;
begin
    if (e=nil) then
       raise NoSuchElementException.create;
    result := e.key;
end;

function TAbstractMap.containsKey(key: IUnknown): boolean;
begin
    result := get(key) <> nil
end;

function TAbstractMap.containsValue(value: IUnknown): boolean;
begin
  raise NotImplementedException.create
end;

function TAbstractMap.isEmpty: boolean;
begin
   result := size = 0
end;

class function TAbstractMap.valEquals(o1, o2: IUnknown): boolean;
begin
   if o1 = nil then
      result := o2 = nil
   else
      result := equal(o1, o2)
end;



function TAbstractMap.get(key: string): IUnknown;
begin
     result := get(iref(key))
end;

function TAbstractMap.getEntry(key: string): IMapEntry;
begin
     result := getEntry(iref(key))
end;

function TAbstractMap.has(key: string): boolean;
begin
     result := has(iref(key))
end;

function TAbstractMap.put(key, value: string): IUnknown;
begin
   result := put(iref(key), iref(value))
end;

function TAbstractMap.remove(key: string): IUnknown;
begin
     result := remove(iref(key))
end;

function TAbstractMap.getStr(key: Iunknown): string;
begin
     result := stringOf(get(key))
end;

function TAbstractMap.getStr(key: string): string;
begin
     result := stringOf(get(key))
end;

function TAbstractMap.entry(key, value: IUnknown): IMapEntry;
begin
    result := TMapEntry.create(key, value) 
end;

procedure TAbstractMap.clear;
var
  i :IIterator;
begin
  i := self.keys;
  while i.hasNext do begin
        i.next;
        i.remove;
  end
end;

function TAbstractMap.put(key: integer; value: IUnknown): IUnknown;
begin
    result := put(iref(key), value)
end;

function TAbstractMap.put(key, value: integer): IUnknown;
begin
   result := put(iref(key), iref(value))
end;

function TAbstractMap.get(key: integer): IUnknown;
begin
   result := get(iref(key))
end;

{ TMapIterator }

constructor TMapIterator.create(base: IIterator);
begin
   assert(base <> nil);
   inherited create;
   _base := base;
end;

function TMapIterator.hasNext: boolean;
begin
  result := _base.hasNext
end;

function TMapIterator.next: IUnknown;
begin
  result := _base.next
end;

procedure TMapIterator.remove;
begin
  _base.remove
end;

{ TMapKeysIterator }

function TMapKeysIterator.next: IUnknown;
begin
  result := (inherited next as IMapEntry).key
end;

{ TMapValuesIterator }

function TMapValuesIterator.next: IUnknown;
begin
  result := (inherited next as IMapEntry).value
end;

{THashSet}
{}
constructor THashSet.create(aLimit :Integer; factor :single);
begin
  assert((aLimit > 0) and (factor >= 0));
  inherited create;
  self._size       := 0;
  self._factor      := factor;
  SetLength(self._items, max(3, aLimit+1));
end;

constructor THashSet.create(aLimit :Integer);
begin
  self.create(aLimit, 1)
end;

constructor THashSet.create;
begin
   self.create(21)
end;

{}
{}
destructor THashSet.Destroy;
begin
   inherited Destroy
end;

{}
{}
function THashSet.size:Integer;
begin
  result := _size
end;

{}
{}
function THashSet.has(item:IUnknown):boolean;
var
  i : integer;
begin
  result := search(item, i)
end;

function THashSet.get(key: IUnknown): IUnknown;
var
  i : integer;
begin
  result := nil;
  i := hashIndex(key);
  if (_items[i] <> nil) and not _items[i].isEmpty then
     result := _items[i].get(key);
end;

function THashSet.limit: Integer;
begin
  result := length(_items)
end;

{}
{}
procedure THashSet.grow;
var
  oldLimit :Integer;
  oldItems :TIListArray;
  i        :Integer;
  j        :IIterator;
  o        :IUnknown;
begin
    oldLimit := limit;
    oldItems := _items;
    _items   := nil;
    _size   := 0;
    setLength(_items, oldLimit*2+1);
    for i := 0 to high(oldItems) do begin
        if oldItems[i] <> nil then begin
            j := oldItems[i].iterator;
            while j.hasNext do begin
               o := j.next;
               self.add(o);
            end
        end
    end;
end;

{}
{}
function THashSet.add(item:IUnknown):boolean;
var
  i :Integer;
begin
   assert(item <> nil);
   if (_factor > 0) and ((limit*_factor - size) < 0) then
      grow;

   if search(item, i) then
     result := false
   else begin
       if _items[i] = nil then
          _items[i] := THashListClass.create;
       result := _items[i].add(item);
       if result then
          inc(_size)
   end
end;

function THashSet.remove(item :IUnknown):IUnknown;
var
  index :integer;
  i     :IIterator;
  o     :IUnknown;
begin
  result := nil;
  index := hashIndex(item);
  if _items[index] <> nil then begin
      i := _items[index].iterator;
      while i.hasNext do begin
          o := i.next;
          if (o = item) or equal(item, o) then begin
             result := o;
             i.remove;
             dec(self._size)
          end
      end;
      if _items[index].isEmpty then
         _items[index] := nil
  end
end;

function  THashSet.search(item :IUnknown; var index:Integer):boolean;
begin
  index  := hashIndex(item);
  result := (_items[index] <> nil) and _items[index].has(item);
end;

function THashSet.hashIndex(item :IUnknown):Integer;
begin
  result := abs(hashOf(item)) mod limit
end;

{}
{}
procedure THashSet.clear;
begin
  _items := nil;
  setLength(_items, max(3, limit));
  _size := 0
end;


function THashSet.Iterator: IIterator;
begin
   result := THashSetIterator.create(self)
end;

{ THashSetIterator }

constructor THashSetIterator.create(owner: THashSet);
begin
   assert(owner <> nil);
   inherited create;

   self._owner  := owner;
   self._holder := owner;

   self._index     :=  nextIndex(0);
   if self._index >= 0 then
      _iter := _owner._items[_index].iterator
   else
      _iter := THashListClass.create.iterator
end;

function THashSetIterator.nextIndex(i :integer) :integer;
begin
     while (i >= 0)
     and  (i < _owner.limit)
     and ((_owner._items[i] = nil) or  _owner._items[i].isEmpty)
     do
         Inc(i);
     if i < _owner.limit then
        result := i
     else
        result := -1
end;

function THashSetIterator.hasNext: boolean;
begin
   gotoNext;
   result := (_index >= 0) and _iter.hasNext
end;

function THashSetIterator.next: IUnknown;
begin
    gotoNext;
    if not hasNext then
       raise NoSuchElementException.create('No more elements');
    if not _iter.hasNext then
      raise NoSuchElementException.create('internal error');
    result := _iter.next;
end;

procedure THashSetIterator.remove;
begin
    _iter.remove;
     dec(_owner._size);
end;

procedure THashSetIterator.gotoNext;
begin
   if not _iter.hasNext and (_index >= 0) then begin
      _index := nextIndex(_index+1);
      if _index >= 0 then
         _iter := _owner._items[_index].iterator
   end
end;

{ THashMap }


constructor THashMap.create(aLimit: Integer; factor: single);
begin
    inherited create;
    _set := THashSet.create(aLimit, factor);
end;

constructor THashMap.create(aLimit: Integer);
begin
  self.create(aLimit, 1)
end;

constructor THashMap.create;
begin
  self.create(21, 1)
end;

function THashMap.put(key, value: IUnknown): IUnknown;
var
  old :IMapEntry;
begin
  result := nil;
  old := _set.get(entry(key)) as IMapEntry;
  if old <> nil then begin
    result := old.value;
    if value = nil then
       _set.remove(old) // not present values are mapped to nil
    else
       old.value := value
  end
  else if value <> nil then begin
     _set.add(entry(key, value));
  end
  // else everything else is mapped to nil by default
end;

function THashMap.remove(key: IUnknown): IUnknown;
begin
   result := _set.remove(entry(key))
end;

function THashMap.size: Integer;
begin
  result := _set.size
end;

function THashMap.entrySet :ISet;
begin
   result := _set
end;

/////////////////////


function THashMap.getEntry(key: IUnknown): IMapEntry;
begin
     result := _set.get(key) as IMapEntry
end;

function THashMap.entries: IIterator;
begin
  result := _set.iterator
end;

procedure THashMap.removeEntry(e: IMapEntry);
begin
    _set.remove(e)
end;

{ TTreeMap }

procedure TTreeMap.incrementSize;
begin
     inc(_modCount);
     inc(_size);
end;

procedure TTreeMap.decrementSize;
begin
     inc(_modCount);
     dec(_size);
end;

constructor TTreeMap.create;
begin
   inherited create;
end;

constructor TTreeMap.create(c :IComparator);
begin
   inherited create;
   self._comparator := c;
end;

constructor TTreeMap.create(other :IMap);
begin
   inherited create;
   putAll(other);
end;

constructor TTreeMap.create(other :ISortedMap);
begin
    _comparator := other.comparator;
    try
      buildFromSorted(other.size, other.entries, inull, inull);
    except
      // java.io.IOException cannotHappen)
      //ClassNotFoundException cannotHappen);
    end;
end;

destructor TTreeMap.destroy;
begin
  while not isEmpty do
    removeEntry(lastEntry);
  inherited destroy;
end;


// Query Operations

function TTreeMap.size :integer;
begin
    result := _size;
end;

function TTreeMap.comparator :IComparator;
begin
    result := _comparator;
end;

function TTreeMap.firstKey :IUnknown;
begin
    result := key(firstEntry);
end;

function TTreeMap.lastKey :IUnknown;
begin
    result := key(lastEntry);
end;

procedure TTreeMap.putAll(other :IMap);
var
   mapSize :integer;
   sset    :ISortedSet;
   c       :IComparator;
begin
    mapSize := other.size;
    other.QueryInterface(ISortedSet, sset);
    if (size=0) and (mapSize<>0) and (sset <> nil) then
    begin
      c := sset.comparator;;
      if (c = comparator) or (c <> nil) and c.equals(comparator) then
      begin
        inc(_modCount);
        try;
            buildFromSorted(mapSize, sset.iterator, inull, inull)
        except
           // java.io.IOException cannotHappen);
           // catch (ClassNotFoundException cannotHappen);
        end;
        EXIT; //////
      end;
    end;
    //ELSE
    inherited putAll(other);
end;

function TTreeMap.getEntry(key :IUnknown) :IMapEntry;
var
   p   :ITreeEntry;
   cmp :integer;
begin
    result := nil;
    p := _root;
    while (result = nil) and (p <> nil) do
    begin
      cmp := compare(key,p.key);
      if (cmp = 0) then
        result := p
      else if (cmp < 0) then
        p := p.left
      else
        p := p.right;
    end;
end;

function TTreeMap.getCeilEntry(key :IUnknown) :ITreeEntry;
var
   p    :ITreeEntry;
   cmp  :integer;
begin
    result := nil;
    p := _root;
    if (p=nil) then EXIT;

    while (result = nil) do
    begin
      cmp := compare(key, p.key);
      if (cmp = 0) then
          result := p
      else if (cmp < 0) then
      begin
        if (p.left <> nil) then
           p := p.left
        else
           result := p
      end
      else if (p.right <> nil) then
          p := p.right
      else
      begin
        while (p.parent <> nil) and (p = p.parent.right) do
          p := p.parent;
        result := p.parent;
      end;
    end;
end;

function TTreeMap.getPrecedingEntry(key :IUnknown) :ITreeEntry;
var
   p    :ITreeEntry;
   cmp  :integer;
begin
    result := nil;
    p := _root;
    if (p=nil) then EXIT;

    while (result = nil) do
    begin
      cmp := compare(key, p.key);
      if (cmp > 0) then
      begin
        if (p.right <> nil) then
          p := p.right
        else
          result := p;
      end
      else if (p.left <> nil) then
        p := p.left
      else
      begin
        while (p.parent <> nil) and (p = p.parent.left) do
          p := p.parent;
        result := p.parent;
      end
    end;
end;

function TTreeMap.put(key, newValue:IUnknown) :IUnknown;
var
   t   :ITreeEntry;
   cmp :Integer;
begin
    result := nil;
    t := _root;
    if (t = nil) then
    begin
        incrementSize;;
        _root := TTreeEntry.create(key, newValue, nil);
        EXIT;
    end;

    while (result = nil) do
    begin
        cmp := compare(key, t.key);
        if (cmp = 0) then
        begin
            result  := t.value;
            t.value := newValue;
            BREAK;
        end
        else if (cmp < 0) then
        begin
            if (t.left <> nil) then
               t := t.left
            else begin
              incrementSize;;
              t.left := TTreeEntry.create(key, newValue, t);
              fixAfterInsertion(t.left);
              break;
            end;
        end
        else
        begin
             // cmp > 0
            if (t.right <> nil) then
               t := t.right
            else
            begin
              incrementSize;
              t.right := TTreeEntry.create(key, newValue, t);
              fixAfterInsertion(t.right);
              break;
            end;
        end;
    end;
end;

function TTreeMap.remove(item :IUnknown) :IUnknown;
var
  p :ITreeEntry;
begin
    result := nil;
    p := getEntry(item) as ITreeEntry;
    if (p <> nil) then begin
       result := p.value;
       removeEntry(p);
    end
end;

procedure TTreeMap.clear;
begin
    inc(_modCount);
    _size := 0;
    _root := nil;
end;

function TTreeMap.clone :IUnknown;
var
   clone : TTreeMap;
begin
    result := nil;
    try
        result := inherited clone as ISortedSet;
    except
       // catch (CloneNotSupportedException e);
        raise InternalError.create
    end;
    clone := (result as IDelphiObject).obj as TTreeMap;

    // Put clone into "virgin" state (except for comparator)
    clone._root     := nil;
    clone._size     := 0;
    clone._modCount := 0;
    clone._keySet   := nil;
    clone._entrySet := nil;
    clone._values   := nil;

    // Initialize clone with our mappings
    try
        clone.buildFromSorted(size, _entrySet.iterator, inull, inull);
    except
      //catch (java.io.IOException cannotHappen);
      //catch (ClassNotFoundException cannotHappen);
    end;
end;

(*!!!
function TTreeMap.subSet(fromElement, toElement :IObject) :ISortedSet;
begin
    !result := TSubSet.create(fromElement, toElement)
end;

function TTreeMap.headSet(toElement :IObject) :ISortedSet;
begin
    result := TSubSet.create(toElement, true)
end;

function TTreeMap.tailSet(fromElement,  :IObject) :ISortedSet;
begin
    result := new SubMap(fromKey, false);
end;
*)

class function TTreeMap.computeRedLevel(sz :integer) :integer;
var
   m :integer;
begin
    result := 0;
    m := sz;
    while (m >= 0) do begin
       inc(result);
       m := (m div 2) -1;
    end
end;

procedure TTreeMap.buildFromSorted( size :integer;
                                    it :IIterator;
                                    str :IUnknown;
                                    defaultVal :IUnknown);
    // throws  java.io.IOException, ClassNotFoundException
begin
    self._size := size;
    _root := buildFromSorted(0, 0, size-1, computeRedLevel(size),
                           it, str, defaultVal);
end;

class function TTreeMap.buildFromSorted(level, lo, hi, redLevel :integer;
                               it  :IIterator;
                               str :IUnknown;
                               defaultVal :IUnknown) :ITreeEntry;
//    throws  java.io.IOException, ClassNotFoundException {
var
  mid    :Integer;
  key,
  value  :IUnknown;
  left,
  right,
  middle,
  entry  :ITreeEntry;
begin
    result := nil;
    if (hi < lo) then EXIT;

    mid := (lo + hi) div 2;

    left  := nil;
    if (lo < mid) then
        left := buildFromSorted(level+1, lo, mid - 1, redLevel,
                               it, str, defaultVal);

    // extract key and/or value from iterator or stream
    if (it <> nil) then
    begin // use iterator
        if (defaultVal=nil) then begin
            entry := it.next as ITreeEntry;
            key   := entry.key;
            value := entry.value;
        end
        else begin
            key   := it.next;
            value := defaultVal;
        end
    end
    else begin // use stream
        raise InternalError.create;
        //key := str.readObject();
        // value := (defaultVal <> nil ? defaultVal : str.readObject());
    end;

    middle :=  TTreeEntry.create(key, value, nil);

    // color nodes in non-full bottommost level red
    if (level = redLevel) then
        middle.color := RED;

    if (left <> nil) then
    begin
        middle.left := left;
        left.parent := middle;
    end;

    if (mid < hi) then
    begin
        right := buildFromSorted(level+1, mid+1, hi, redLevel,
                                      it, str, defaultVal);
        middle.right := right;
        right.parent := middle;
    end;

    result := middle;
end;

function TTreeMap.firstEntry :IMapEntry;
var
  e :ITreeEntry;
begin
    e := _root;
    if (e <> nil) then begin
        while (e.left <> nil) do
            e := e.left;
    end;
    result := e
end;

function TTreeMap.lastEntry :IMapEntry;
var
  e :ITreeEntry;
begin
    e := _root;
    if (e <> nil) then begin
        while (e.right <> nil) do
            e := e.right;
    end;
    result := e
end;

class function TTreeMap.successor(t :ITreeEntry) :ITreeEntry;
var
  ch :ITreeEntry;
begin
    result := nil;
    if (t = nil) then EXIT;

    if (t.right <> nil) then
    begin
        result := t.right;
        while (result.left <> nil) do
            result := result.left;
    end
    else
    begin
        result := t.parent;
        ch     := t;
        while (result <> nil) and (ch = result.right) do
        begin
            ch := result;
            result  := result.parent;
        end
    end;
end;


class function TTreeMap.colorOf(p :ITreeEntry):boolean;
begin
   if p = nil then
      result := BLACK
   else
      result := p.color
end;

class function TTreeMap.parentOf(p :ITreeEntry) :ITreeEntry;
begin
    if p = nil then
       result := nil
    else
       result := p.parent;
end;

class procedure TTreeMap.setColor(p :ITreeEntry; c :boolean);
begin
    if (p <> nil) then p.color := c;
end;

class function TTreeMap.leftOf(p :ITreeEntry) :ITreeEntry;
begin
    if p = nil then
       result := nil
    else
       result := p.left;
end;

class function TTreeMap.rightOf(p :ITreeEntry):ITreeEntry;
begin
    if p = nil then
       result := nil
    else
       result := p.right;
end;

procedure TTreeMap.rotateLeft(p :ITreeEntry);
var
  r :ITreeEntry;
begin
    r := p.right;
    p.right := r.left;
    if (r.left <> nil) then
        r.left.parent := p;
    r.parent := p.parent;
    if (p.parent = nil) then
        _root := r
    else if (p.parent.left = p) then
        p.parent.left := r
    else
        p.parent.right := r;
    r.left := p;
    p.parent := r;
end;

procedure TTreeMap.rotateRight(p :ITreeEntry);
var
   l :ITreeEntry;
begin
    l := p.left;
    p.left := l.right;
    if (l.right <> nil) then
        l.right.parent := p;
    l.parent := p.parent;
    if (p.parent = nil) then
        _root := l
    else if (p.parent.right = p) then
        p.parent.right := l
    else
        p.parent.left := l;
    l.right := p;
    p.parent := l;
end;


procedure TTreeMap.fixAfterInsertion(x :ITreeEntry);
var
  y :ITreeEntry;
begin
    x.color := RED;
    while (x <> nil) and (x <> _root) and (x.parent.color = RED) do begin
        if (parentOf(x) = leftOf(parentOf(parentOf(x)))) then begin
            y := rightOf(parentOf(parentOf(x)));
            if (colorOf(y) = RED) then begin
                setColor(parentOf(x), BLACK);
                setColor(y, BLACK);
                setColor(parentOf(parentOf(x)), RED);
                x := parentOf(parentOf(x));
            end
            else begin
                if (x = rightOf(parentOf(x))) then begin
                    x := parentOf(x);
                    rotateLeft(x);
                end;
                setColor(parentOf(x), BLACK);
                setColor(parentOf(parentOf(x)), RED);
                if (parentOf(parentOf(x)) <> nil) then
                    rotateRight(parentOf(parentOf(x)));
            end
        end
        else begin
            y := leftOf(parentOf(parentOf(x)));
            if (colorOf(y) = RED) then begin
                setColor(parentOf(x), BLACK);
                setColor(y, BLACK);
                setColor(parentOf(parentOf(x)), RED);
                x := parentOf(parentOf(x));
            end
            else begin
                if (x = leftOf(parentOf(x))) then begin
                    x := parentOf(x);
                    rotateRight(x);
                end;
                setColor(parentOf(x),  BLACK);
                setColor(parentOf(parentOf(x)), RED);
                if (parentOf(parentOf(x)) <> nil) then
                    rotateLeft(parentOf(parentOf(x)));
            end
        end
    end;
    _root.color := BLACK;
end;

procedure TTreeMap.removeEntry(e :IMapEntry);
var
  p, s,
  replacement :ITreeEntry;
begin
    p := e as ITreeEntry;
    decrementSize();
    // If strictly internal, first swap position with successor.
    if (p.left <> nil) and (p.right <> nil) then
    begin
      s := successor(p);
      swapPosition(s, p);
    end;

    // Start fixup at replacement node, if it exists.
    if p.left <> nil then
      replacement := p.left
    else
      replacement := p.right;

    if (replacement <> nil) then
    begin
      // Link replacement to parent
      replacement.parent := p.parent;
      if (p.parent = nil) then
          _root := replacement
      else if (p = p.parent.left) then
          p.parent.left  := replacement
      else
          p.parent.right := replacement;

      // null out links so they are OK to use by fixAfterDeletion.
      p.left  := nil;
      p.right := nil;
      p.parent := nil;

      // Fix replacement
      if (p.color = BLACK) then
          fixAfterDeletion(replacement);
    end
    else if (p.parent = nil) then // return if we are the only node.
      _root := nil
    else
    begin //  No children. Use self as phantom replacement and unlink.
      if (p.color = BLACK) then
          fixAfterDeletion(p);

      if (p.parent <> nil) then
      begin
         if (p = p.parent.left) then
            p.parent.left := nil
        else if (p = p.parent.right) then
            p.parent.right := nil;
        p.parent := nil;
      end
    end
end;

procedure TTreeMap.fixAfterDeletion(x :ITreeEntry);
var
   sib :ITreeEntry;
begin
    while (x <> _root) and (colorOf(x) = BLACK) do begin
        if (x = leftOf(parentOf(x))) then begin
            sib := rightOf(parentOf(x));

            if (colorOf(sib) = RED) then begin
                setColor(sib, BLACK);
                setColor(parentOf(x), RED);
                rotateLeft(parentOf(x));
                sib := rightOf(parentOf(x));
            end;

            if  (colorOf(leftOf(sib))  = BLACK) and
                (colorOf(rightOf(sib)) = BLACK) then begin
                setColor(sib,  RED);
                x := parentOf(x);
            end
            else begin
                if (colorOf(rightOf(sib)) = BLACK) then begin
                    setColor(leftOf(sib), BLACK);
                    setColor(sib, RED);
                    rotateRight(sib);
                    sib := rightOf(parentOf(x));
                end;
                setColor(sib, colorOf(parentOf(x)));
                setColor(parentOf(x), BLACK);
                setColor(rightOf(sib), BLACK);
                rotateLeft(parentOf(x));
                x := _root;
            end
        end
        else begin // symmetric
            sib := leftOf(parentOf(x));

            if (colorOf(sib) = RED) then begin
                setColor(sib, BLACK);
                setColor(parentOf(x), RED);
                rotateRight(parentOf(x));
                sib := leftOf(parentOf(x));
            end;

            if (colorOf(rightOf(sib)) = BLACK) and
                (colorOf(leftOf(sib)) = BLACK) then begin
                setColor(sib,  RED);
                x := parentOf(x);
            end
            else begin
                if (colorOf(leftOf(sib)) = BLACK) then begin
                    setColor(rightOf(sib), BLACK);
                    setColor(sib, RED);
                    rotateLeft(sib);
                    sib := leftOf(parentOf(x));
                end;
                setColor(sib, colorOf(parentOf(x)));
                setColor(parentOf(x), BLACK);
                setColor(leftOf(sib), BLACK);
                rotateRight(parentOf(x));
                x := _root;
            end
        end
    end;
    setColor(x, BLACK);
end;

procedure TTreeMap.swapPosition(x, y :ITreeEntry);
var
  px, py,
  lx, ly,
  rx, ry :ITreeEntry;
  c,
  xWasLeftChild,
  yWasLeftChild :boolean;
begin
    // Save initial values.
    px := x.parent; lx := x.left; rx := x.right;
    py := y.parent; ly := y.left; ry := y.right;
    xWasLeftChild := (px <> nil) and (x = px.left);
    yWasLeftChild := (py <> nil) and (y = py.left);

    // Swap, handling special cases of one being the other's parent.
    if (x = py) then
    begin  // x was y's parent
      x.parent := y;
      if (yWasLeftChild) then
      begin
        y.left := x;
        y.right := rx;
      end
      else
      begin
        y.right := x;
        y.left := lx;
      end
    end
    else
    begin
      x.parent := py;
      if (py <> nil) then
      begin
        if (yWasLeftChild) then
          py.left := x
        else
          py.right := x;
      end;
      y.left := lx;
      y.right := rx;
    end;

    if (y = px) then
    begin // y was x's parent
      y.parent := x;
      if (xWasLeftChild) then
      begin
        x.left := y;
        x.right := ry;
      end
      else
      begin
        x.right := y;
        x.left := ly;
      end
    end
    else
    begin
      y.parent := px;
      if (px <> nil) then
      begin
        if (xWasLeftChild) then
          px.left := y
        else
          px.right := y;
      end;
      x.left := ly;
      x.right := ry;
    end;

    // Fix children's parent pointers
    if (x.left <> nil) then
      x.left.parent := x;
    if (x.right <> nil) then
      x.right.parent := x;
    if (y.left <> nil) then
      y.left.parent := y;
    if (y.right <> nil) then
      y.right.parent := y;

    // Swap colors
    c := x.color;
    x.color := y.color;
    y.color := c;

    // Check if root changed
    if (_root = x) then
      _root := y
    else if (_root = y) then
      _root := x;
end;


procedure TTreeMap.addAllForTreeSet(aset :ISortedSet; defaultVal :IUnknown);
begin
  buildFromSorted(aset.size(), aset.iterator(), inull, defaultVal)
end;

function TTreeMap.compare(k1, k2 :IUnknown) :integer;
var
 c :IComparable;
begin
  if _comparator <> nil then
     result := _comparator.compare(k1, k2)
  else if k1 = k2 then
     result := 0
  else if k1 = nil then
     result := -1
  else if k2 = nil then
     result := 1
  else if k1.queryInterface(IComparable, c) = 0 then
     result := c.compareTo(k2)
  else if k2.queryInterface(IComparable, c) = 0 then
     result := c.compareTo(k1)
  else
     raise UnsupportedOperationException.create
end;

function TTreeMap.containsKey(key :IUnknown) :boolean;
begin
    result := get(key) <> nil;
end;

function TTreeMap.containsValue(value :IUnknown) :boolean;
begin
    result := false;
    if _root <> nil then begin
       if value = nil then
          result := valueSearchNull(_root)
       else
          result := valueSearchNonNull(_root, value);
    end
end;

function TTreeMap.valueSearchNull(n :ITreeEntry) :boolean;
begin

    if (n.value = nil) then
       result := true
    else
      // Check left and right subtrees for value
        result := (n.left  <> nil) and valueSearchNull(n.left)
                  or (n.right <> nil) and valueSearchNull(n.right)
end;

function TTreeMap.valueSearchNonNull(n :ITreeEntry; value :IUnknown) :boolean;
begin
    // Check self node for the value
    if equal(value, n.value) then
       result := true
    else
    // Check left and right subtrees for value
        result := (n.left  <> nil) and valueSearchNonNull(n.left, value)
                  or (n.right <> nil) and valueSearchNonNull(n.right, value)
end;

function TTreeMap.entries: IIterator;
begin
  result := TTreeIterator.create(self)
end;


{ TMapView }

constructor TMapView.create(owner :TAbstractMap);
begin
   inherited create;
   self._myMap := owner;
end;

function TMapView.size :integer;
begin
     result := _myMap.size;;
end;

procedure TMapView.clear;
begin
     _myMap.clear;
end;

{ TEntryView }

function TEntryView.iterator :IIterator;
begin
  result := _myMap.entrySet.iterator
end;

function TEntryView.has(o :IUnknown) :boolean;
var
  e :IMapEntry;
begin
  o.QueryInterface(IMapEntry, e);
  if e = nil then
     result := false
  else
     result := _myMap.containsKey(e.key)
end;

function TEntryView.remove(o :IUnknown) :IUnknown;
var
  e :IMapEntry;
begin
  o.QueryInterface(IMapEntry, e);
  if e = nil then
     result := nil
  else
     result := _myMap.remove(e.key);
end;

{ TKeyView }

function TKeyView.iterator :IIterator;
begin
  result := _myMap.keys
end;

function TKeyView.has(o :IUnknown) :boolean;
begin
  result := _myMap.containsKey(o);
end;

function TKeyView.remove(o :IUnknown) :IUnknown;
begin
  result := _myMap.remove(o);
end;

{ TValueView }

function TValueView.iterator :IIterator;
begin
  result := TMapValuesIterator.create(_myMap.entries)
end;

function TValueView.has(o :IUnknown) :boolean;
begin
  result := _myMap.containsValue(o);
end;

function TValueView.remove(o :IUnknown) :IUnknown;
var
  i :IIterator;
  e :IMapEntry;
begin
  result := nil;
  i := _myMap.entries;
  while (result = nil) and i.hasNext do begin
      e := i.next as IMapEntry;
      if _myMap.valEquals(e.value, o) then begin
         result := e.value;
         _myMap.removeEntry(e);
      end
  end
end;

{ TTreeEntry }

constructor TTreeEntry.create(key, value: IUnknown; parent: ITreeEntry);
begin
  inherited create(key, value);
  self._parent := Pointer(parent as IInterface);
end;

function TTreeEntry.getColor: boolean;
begin
  result := _color
end;

function TTreeEntry.getLeft: ITreeEntry;
begin
  result := _left
end;

function TTreeEntry.getParent: ITreeEntry;
begin
  result := IInterface(_parent) as ITreeEntry;
end;

function TTreeEntry.getRight: ITreeEntry;
begin
  result := _right
end;

function TTreeEntry.isBlack: boolean;
begin
  result := _color = BLACK
end;

function TTreeEntry.isRed: boolean;
begin
  result := _color = RED
end;

procedure TTreeEntry.setBlack;
begin
  _color := BLACK
end;

procedure TTreeEntry.setColor(color: boolean);
begin
  self._color := color
end;

procedure TTreeEntry.setLeft(t: ITreeEntry);
begin
  self._left := t
end;

procedure TTreeEntry.setParent(t: ITreeEntry);
begin
  self._parent := Pointer(t as IInterface);
end;

procedure TTreeEntry.setRed;
begin
  self._color := RED
end;

procedure TTreeEntry.setRight(t: ITreeEntry);
begin
  self._right := t
end;

function TTreeEntry.compareTo(other :IUnknown): Integer;
begin
   result := (self.key as IComparable).compareTo((other as ITreeEntry).key)
end;

{ TTreeSet }

constructor TTreeSet.create;
begin
   inherited create;
   _sset := TTreeMap.create;
end;

constructor TTreeSet.create(c: IComparator);
begin
   inherited create;
   _sset := TTreeMap.create(c);
end;

constructor TTreeSet.create(other: ISortedSet);
begin
  inherited create;
  _sset := TTreeMap.create(other.comparator);
  addAll(other);
end;

constructor TTreeSet.create(other: ISet);
begin
  self.create;
  addAll(other);
end;

function TTreeSet.comparator: IComparator;
begin
   result := _sset.comparator
end;

function TTreeSet.size: integer;
begin
     result := _sset.size
end;

function  TTreeSet.add(item:IUnknown):boolean;
begin
   _sset.put(item, inull);
   result := true;
end;

function  TTreeSet.iterator :IIterator;
begin
  result := _sset.keys
end;

{ TTreeIterator }

constructor TTreeIterator.create(aset :TTreeMap);
begin
    inherited create;
    _myMap := aset;
    _next  := _myMap.firstEntry as ITreeEntry;
    _expectedModCount := _myMap._modCount;
end;

constructor TTreeIterator.create(aset :TTreeMap; first, firstExcluded :ITreeEntry);
begin
    inherited Create;
    _myMap := aset;
    _next := first;
    _firstExcluded     := firstExcluded;
    _expectedModCount  := _myMap._modCount;
end;

function TTreeIterator.hasNext:boolean;
begin
    result := _next <> _firstExcluded;
end;

function TTreeIterator.next :IUnknown;
begin
    if (_next = _firstExcluded) then
        raise NoSuchElementException.create;
    if (_myMap._modCount <> _expectedModCount) then
        raise ConcurrentModificationException.create;

    _lastReturned := _next;
    _next := _myMap.successor(_next);
    result := _lastReturned
end;

procedure TTreeIterator.remove;
begin
    if (_lastReturned = inull) then
        raise IllegalStateException.create;
    if (_myMap._modCount <> _expectedModCount) then
        raise ConcurrentModificationException.create;

    _myMap.removeEntry(_lastReturned);
    inc(_expectedModCount);
    _lastReturned := nil;
end;

{ TAbstractIterator }

function TAbstractIterator.nextStr: string;
begin
     result := stringOf(next)
end;

{ TStack }

constructor TStack.create(items: IList);
begin
   inherited create;
   _items := items
end;

function TStack.top: IUnknown;
begin
  result := _items.last
end;

function TStack.bottom: IUnknown;
begin
  result := _items.first
end;

function TStack.size: Integer;
begin
  result := _items.size
end;

function TStack.has(Item: IUnknown): Boolean;
begin
  result := _items.has(item)
end;

function TStack.pop: IUnknown;
begin
  result := top;
  _items.remove(_items.size-1)
end;

function TStack.indexOf(Item: IUnknown): Integer;
begin
  result := _items.indexOf(item)
end;

function TStack.push(item: IUnknown) :integer;
begin
  _items.add(item);
  result := size;
end;

function TStack.squash :IUnknown;
begin
  result := _items.remove(0)
end;

function TStack.isEmpty: boolean;
begin
  result := _items.isEmpty
end;

function TStack.isFull: boolean;
begin
  result := _items.isFull
end;

function TStack.remove(item :IUnknown) :IUnknown;
begin
  result := _items.remove(item);
end;

function  TStack.items :IList;
begin
   result := _items;
end;

procedure TStack.clear;
begin
   _items.clear;
end;

{ THeap }

function THeap.top: IUnknown;
begin
  result := _items.first;
end;

function THeap.bottom: IUnknown;
begin
  result := _items.last;
end;

function THeap.squash :IUnknown;
begin
  result := _items.last;
  put(size-1, nil);
  _items.remove(size-1);
end;

function THeap.pop :IUnknown;
begin
  result := deheap(0);
end;

function THeap.deheap(i :integer): IUnknown;
var
  j       :integer;
  item    :IUnknown;
  child   :IUnknown;
  sibling :IUnknown;
begin
  result := put(i, nil);
  item := squash;
  if _items.size = 0 then
    EXIT;

  j := 1+2*i;
  while j < _items.size do
  begin
    child := _items[j];
    if (j+1) < _items.size then
    begin
      sibling := _items[j+1];
      if compare(child, sibling) > 0 then
      begin
        j := j+1;
        child := sibling;
      end;
    end;
    if compare(item, child) <= 0 then
      BREAK
    else
    begin
      put(i, child);
      i := j;
      j := 1+2*i;
    end
  end;
  put(i, item);
end;

function THeap.push(item: IUnknown) :integer;
begin
  _items.add(item);
  put(size-1, item);
  result := decant(size-1);
end;

function THeap.decant(j :integer):integer;
var
  i      :Integer;
  item   :IUnknown;
  parent :IUnknown;
begin
  item := _items[j];
  while j > 0 do
  begin
    i := (j-1) div 2;
    parent := _items[i];
    if compare(item, parent) >= 0 then
      BREAK
    else begin
      put(j, parent);
      j := i;
    end
  end;
  put(j, item);
  result := j;
end;

function  THeap.remove(item :IUnknown):IUnknown;
begin
  result := searchdel(item, 0);
end;

function  THeap.searchdel(item :IUnknown; i :integer):IUnknown;
var
  j       :integer;
  c       :integer;
begin
  result := nil;
  if i < size then
  begin
    j := 1+2*i;
    c := compare(item, _items[i]);
    if c = 0 then
      result := deheap(i)
    else if (c > 0) and (j < _items.size) then
    begin
      result := searchdel(item, j);
      if (result = nil)
      and ((j+1) < _items.size) then
        result := searchdel(item, j+1);
    end
  end
end;

function  THeap.check :boolean;
var
  i :integer;
  c :integer;
begin
  result := true;
  for i := 1 to size-1 do
  begin
    c := compare(_items[i], _items[(i-1) div 2]);
    if c < 0 then
    begin
      result := false;
      BREAK;
    end;
  end;
end;

function  THeap.compare(o1, o2 :IUnknown) :integer;
begin
   result := JALCollections.compare(o1, o2);
end;

function THeap.put(i :integer; item :IUnknown):IUnknown;
begin
  result := _items[i];
  _items[i] := item;
end;


end.




