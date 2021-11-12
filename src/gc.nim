# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.


type
  ObjKind = enum
    okInt, okPair
  PObj = ptr Obj
  Obj = object
    marked: bool
    case kind: ObjKind
    of okInt:
      val: int
    of okPair:
      head, tail: PObj
  Vm = object
    stack: seq[PObj]
    objects: seq[PObj]
    gcThreshold: Natural

const 
  GCIntialThreshold = 256

proc gc(vm: var Vm)

proc newVm(): Vm =
  Vm(stack: @[], objects: @[], gcThreshold: GCIntialThreshold)

proc push(v: var Vm, o: PObj)=
  v.stack.add(o)

proc pop(v: var Vm): PObj =
  if v.stack.len() == 0:
    raise newException(Exception, "Stack underflow");
  v.stack.pop()

proc newPObj(vm: var Vm): PObj =
  if vm.objects.len() >= vm.gcThreshold:
    gc(vm)
  result = create(Obj)
  vm.objects.add(result)


proc newIntObj(vm: var Vm, v: int): PObj =
  result = newPObj(vm)
  result.kind = okInt
  result.val = v

proc newPairObj(vm: var Vm, head, tail: PObj): PObj =
  result = newPObj(vm)
  result.kind = okPair
  result.head = head
  result.tail = tail

proc mark(o: PObj)=
  if o.marked:
    return
  o.marked = true
  case o.kind
  of okPair:
    mark(o.head)
    mark(o.tail)
  else:
    discard

proc markAll(v: var Vm)=
  for obj in v.stack:
    mark(obj)

proc sweep(vm: var Vm)=
  var toFree: seq[int] = @[]
  for i, obj in vm.objects:
    if obj.marked:
      obj.marked = false;
    else:
      toFree.add(i)
  
  for i in toFree:
    let obj = vm.objects[i]
    dealloc(obj)
    vm.objects.delete(i)

proc gc(vm: var Vm)=
  markAll(vm)
  sweep(vm)


when isMainModule:
  echo("Hello, World!")
