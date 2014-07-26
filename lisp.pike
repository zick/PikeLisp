int kLPar = '(';
int kRPar = ')';
int kQuote = '\'';

class LObj {
}

class Nil {
  inherit LObj;
}
LObj kNil = Nil();
bool nilp(LObj x) { return _typeof(x) == _typeof(kNil); }

class Num {
  inherit LObj;
  int num;
  void create(int n) { num = n; }
}
LObj kNum = Num(0);
bool nump(LObj x) { return _typeof(x) == _typeof(kNum); }

class Sym {
  inherit LObj;
  string str;
  void create(string s) { str = s; }
}
LObj kSym = Sym("");
bool symp(LObj x) { return _typeof(x) == _typeof(kSym); }

mapping sym_table = (["nil":kNil]);
LObj makeSym(string s) {
  if (!sym_table[s]) {
    sym_table[s] = Sym(s);
  }
  return sym_table[s];
}
LObj sym_t = makeSym("t");
LObj sym_quote = makeSym("quote");
LObj sym_if = makeSym("if");
LObj sym_lambda = makeSym("lambda");
LObj sym_defun = makeSym("defun");
LObj sym_setq = makeSym("setq");

class Error {
  inherit LObj;
  string str;
  void create(string s) { str = s; }
}
LObj kError = Error("");
bool errorp(LObj x) { return _typeof(x) == _typeof(kError); }

class Cons {
  inherit LObj;
  LObj car;
  LObj cdr;
  void create(LObj a, LObj d) { car = a; cdr = d; }
}
LObj kCons = Cons(kNil, kNil);
bool consp(LObj x) { return _typeof(x) == _typeof(kCons); }

class Subr {
  inherit LObj;
  mixed fn;
  void create(mixed f) { fn = f; }
}
LObj kSubr = Subr(0);
bool subrp(LObj x) { return _typeof(x) == _typeof(kSubr); }

class Expr {
  inherit LObj;
  LObj args;
  LObj body;
  LObj env;
  void create(LObj a, LObj b, LObj e) { args = a; body = b; env = e; }
}
LObj kExpr = Expr(kNil, kNil, kNil);
bool exprp(LObj x) { return _typeof(x) == _typeof(kExpr); }

LObj safeCar(LObj x) {
  if (consp(x)) return x.car;
  return kNil;
}

LObj safeCdr(LObj x) {
  if (consp(x)) return x.cdr;
  return kNil;
}

LObj makeExpr(LObj args, LObj env) {
  return Expr(safeCar(args), safeCdr(args), env);
}

LObj nreverse(LObj lst) {
  LObj ret = kNil;
  while (consp(lst)) {
    LObj tmp = lst.cdr;
    lst.cdr = ret;
    ret = lst;
    lst = tmp;
  }
  return ret;
}

LObj pairlis(LObj lst1, LObj lst2) {
  LObj ret = kNil;
  while (consp(lst1) && consp(lst2)) {
    ret = Cons(Cons(lst1.car, lst2.car), ret);
    lst1 = lst1.cdr;
    lst2 = lst2.cdr;
  }
  return nreverse(ret);
}

bool spacep(int c) {
  return c == '\t' || c == '\r' || c == '\n' || c == ' ';
}

bool delimiterp(int c) {
  return c == kLPar || c == kRPar || c == kQuote || spacep(c);
}

string skipSpaces(string s) {
  int i;
  for (i = 0; i < strlen(s); ++i) {
    if (!spacep(s[i])) {
      break;
    }
  }
  return s[i..strlen(s) - 1];
}

LObj makeNumOrSym(string s) {
  int n = (int)s;
  if ((string)n == s) {
    return Num(n);
  }
  return makeSym(s);
}

class ParseState {
  LObj obj;
  string next;
  void create(LObj o, string s) { obj = o; next = s; }
}
ParseState parseError(string s) { return ParseState(Error(s), ""); }

ParseState readAtom(string s) {
  string next = "";
  for (int i = 0; i < strlen(s); ++i) {
    if (delimiterp(s[i])) {
      next = s[i..strlen(s) - 1];
      s = s[0..i - 1];
      break;
    }
  }
  return ParseState(makeNumOrSym(s), next);
}

ParseState read(string s) {
  s = skipSpaces(s);
  if (strlen(s) == 0) {
    return parseError("empty input");
  } else if (s[0] == kRPar) {
    return parseError("invalid syntax: " + s);
  } else if (s[0] == kLPar) {
    return readList(s[1..strlen(s) - 1]);
  } else if (s[0] == kQuote) {
    ParseState tmp = read(s[1..strlen(s) - 1]);
    return ParseState(Cons(sym_quote, Cons(tmp.obj, kNil)), tmp.next);
  }
  return readAtom(s);
}

ParseState readList(string s) {
  LObj ret = kNil;
  while (true) {
    s = skipSpaces(s);
    if (strlen(s) == 0) {
      return parseError("unfinished parenthesis");
    } else if (s[0] == kRPar) {
      break;
    }
    ParseState tmp = read(s);
    if (errorp(tmp.obj)) {
      return tmp;
    }
    ret = Cons(tmp.obj, ret);
    s = tmp.next;
  }
  return ParseState(nreverse(ret), s[1..strlen(s) - 1]);
}

string printObj(LObj obj) {
  if (nilp(obj)) {
    return "nil";
  } else if (nump(obj)) {
    return (string)obj.num;
  } else if (symp(obj)) {
    return obj.str;
  } else if (errorp(obj)) {
    return "<error: " + obj.str + ">";
  } else if (consp(obj)) {
    return printList(obj);
  } else if (subrp(obj)) {
    return "<subr>";
  } else if (exprp(obj)) {
    return "<expr>";
  } else {
    return "<unknown>";
  }
}

string printList(LObj obj) {
  string ret = "";
  bool first = true;
  while (consp(obj)) {
    if (first) {
      first = false;
    } else {
      ret += " ";
    }
    ret += printObj(obj.car);
    obj = obj.cdr;
  }
  if (obj == kNil) {
    return "(" + ret + ")";
  } else {
    return "(" + ret + " . " + printObj(obj) + ")";
  }
}

LObj findVar(LObj sym, LObj env) {
  while (consp(env)) {
    LObj alist = env.car;
    while (consp(alist)) {
      if (alist.car.car == sym) {
        return alist.car;
      }
      alist = alist.cdr;
    }
    env = env.cdr;
  }
  return kNil;
}

LObj g_env = Cons(kNil, kNil);

void addToEnv(LObj sym, LObj val, LObj env) {
  env.car = Cons(Cons(sym, val), env.car);
}

LObj eval(LObj obj, LObj env) {
  if (nilp(obj) || nump(obj) || errorp(obj)) {
    return obj;
  } else if (symp(obj)) {
    LObj bind = findVar(obj, env);
    if (bind == kNil) {
      return Error(obj.str + " has no value");
    }
    return bind.cdr;
  }
  LObj op = safeCar(obj);
  LObj args = safeCdr(obj);
  if (op == sym_quote) {
    return safeCar(args);
  } else if (op == sym_if) {
    LObj c = eval(safeCar(args), env);
    if (errorp(c)) {
      return c;
    } else if (c == kNil) {
      return eval(safeCar(safeCdr(safeCdr(args))), env);
    }
    return eval(safeCar(safeCdr(args)), env);
  } else if (op == sym_lambda) {
    return makeExpr(args, env);
  } else if (op == sym_defun) {
    LObj expr = makeExpr(safeCdr(args), env);
    LObj sym = safeCar(args);
    addToEnv(sym, expr, g_env);
    return sym;
  } else if (op == sym_setq) {
    LObj val = eval(safeCar(safeCdr(args)), env);
    if (errorp(val)) return val;
    LObj sym = safeCar(args);
    LObj bind = findVar(sym, env);
    if (bind == kNil) {
      addToEnv(sym, val, g_env);
    } else {
      bind.cdr = val;
    }
    return val;
  }
  return apply(eval(op, env), evlis(args, env));
}

LObj evlis(LObj lst, LObj env) {
  LObj ret = kNil;
  while (consp(lst)) {
    LObj elm = eval(lst.car, env);
    if (errorp(elm)) {
      return elm;
    }
    ret = Cons(elm, ret);
    lst = lst.cdr;
  }
  return nreverse(ret);
}

LObj progn(LObj body, LObj env) {
  LObj ret = kNil;
  while (consp(body)) {
    ret = eval(body.car, env);
    body = body.cdr;
  }
  return ret;
}

LObj apply(LObj fn, LObj args) {
  if (errorp(fn)) {
    return fn;
  } else if (errorp(args)) {
    return args;
  } else if (subrp(fn)) {
    return fn.fn(args);
  } else if (exprp(fn)) {
    return progn(fn.body, Cons(pairlis(fn.args, args), fn.env));
  }
  return Error(printObj(fn) + " is not function");
}

LObj subrCar(LObj args) {
  return safeCar(safeCar(args));
}

LObj subrCdr(LObj args) {
  return safeCdr(safeCar(args));
}

LObj subrCons(LObj args) {
  return Cons(safeCar(args), safeCar(safeCdr(args)));
}

int main()
{
  addToEnv(sym_t, sym_t, g_env);
  addToEnv(makeSym("car"), Subr(subrCar), g_env);
  addToEnv(makeSym("cdr"), Subr(subrCdr), g_env);
  addToEnv(makeSym("cons"), Subr(subrCons), g_env);
  write("> ");
  while(string line = Stdio.stdin.gets()) {
    LObj o = makeNumOrSym(line);
    ParseState s = read(line);
    write("%s", printObj(eval(s.obj, g_env)));
    write("\n> ");
  }
}
