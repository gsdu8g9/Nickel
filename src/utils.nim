# Файл с различными хелперами

# Стандартная библиотека
import macros, strtabs, times, strutils, future, random
# Nimble
import strfmt
# Сторонние пакеты
import termcolor
# Свои пакеты
import types

# http://stackoverflow.com/questions/31948131/unpack-multiple-variables-from-sequence
macro extract*(args: varargs[untyped]): typed =
  ## assumes that the first expression is an expression
  ## which can take a bracket expression. Let's call it
  ## `arr`. The generated AST will then correspond to:
  ##
  ## let <second_arg> = arr[0]
  ## let <third_arg>  = arr[1]
  ## ...
  result = newStmtList()
  # the first vararg is the "array"
  let arr = args[0]
  var i = 0
  # all other varargs are now used as "injected" let bindings
  for arg in args.children:
    if i > 0:
      var rhs = newNimNode(nnkBracketExpr)
      rhs.add(arr)
      rhs.add(newIntLitNode(i-1))

      let assign = newLetStmt(arg, rhs) # could be replaced by newVarStmt
      result.add(assign)
    i += 1
  #echo result.treerepr

template benchmark*(benchmarkName: string, code: stmt) =
  let startTime = epochTime()
  code
  let elapsed = epochTime() - startTime
  let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
  echo "Затрачено ", elapsedStr, " секунд на [", benchmarkName, "]"



proc api*(keyValuePairs: varargs[tuple[key, val: string]]): StringTableRef = 
  ## Возвращает новую строковую таблицу, может использоваться
  ## вот так: var info = {"message":"Hello", "peer_id": "123"}.api
  return newStringTable(keyValuePairs, modeCaseInsensitive)

proc getMoscowTime*(): string =
  ## Возвращает время в формате день.месяц.год часы:минуты:секунды по МСК
  let curTime = getGmTime(getTime()) + initInterval(hours=3)
  return format(curTime, "d'.'M'.'yyyy HH':'mm':'ss")

proc log*(style: ref Style, data: string) =
  ## Выводит сообщение data со стилем style в консоль с указанием времени 
  stdout.write("\e[0;32m")  # Синий цвет
  stdout.write("[" & getClockStr() & "] ")  # Пишем время 
  colored(style, data)  # Пишем само сообщение

proc log*(msg: Message, command: bool) = 
  ## Логгирует объект сообщения в консоль
  let `from` = "https://vk.com/id" & $msg.peerId
  if command:
    var args = ""
    if len(msg.cmd.arguments) > 0:
      args = "с аргументами " & msg.cmd.arguments.join(", ")
    else:
      args = "без аргументов"
    log(termcolor.Success, interp"${`from`} > Команда `${msg.cmd.command}` $args")
  else:
    log(termcolor.Hint, interp"Сообщение `${msg.body}` от ${`from`}")

macro logWithStyle*(val: ref Style, body: untyped): untyped = 
  result = newStmtList()
  # проверяем, что body - список выражений
  expectKind body, nnkStmtList
  for elem in body:
    # Скобки
    expectKind elem, nnkPar
    # Длина - 1 элемент
    expectLen elem, 1
    # Получаем то, что нам нужно вывести
    let toWrite = elem[0]
    # Добавляем выражение к результату
    result.add quote do:
      log(`val`, `toWrite`)

proc antiFlood*(): string =
   ## Служит ля обхода анти-флуда Вконтакте (генерирует пять случайных букв)
   const Alphabet = "ABCDEFGHIJKLMNOPQRSTUWXYZ"
   return lc[random(Alphabet) | (x <- 0..4), char].join("")