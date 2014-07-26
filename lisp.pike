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

LObj safeCar(LObj x) {
  if (consp(x)) return x.car;
  return kNil;
}

LObj safeCdr(LObj x) {
  if (consp(x)) return x.cdr;
  return kNil;
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
  return Error("noimpl");
}

int main()
{
  addToEnv(sym_t, sym_t, g_env);
  write("> ");
  while(string line = Stdio.stdin.gets()) {
    LObj o = makeNumOrSym(line);
    ParseState s = read(line);
    write("%s", printObj(eval(s.obj, g_env)));
    write("\n> ");
  }
}
