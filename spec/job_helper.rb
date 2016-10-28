# monkey patch needed for Zip::InputStream.open_buffer
class StringIO
  def path
  end
end

NAME_A   = "PromiseA2"
SCRIPT_A = <<EOS
Y:
    q =? nil
    s =? 0.875
    a = Y(p_title="aaa", q=q, s=s, p_timeout=3) | ['b']
    b = Y(p_title="bbb", q=q, s=s, p_timeout=3) | ['e']
    e = if q == s then ERR("xxx") else q-s
    z = Gemini::Helper.sleep(s) && s
    d = [Y(p_title="z/a %d" % i, q=i, s=s, p_timeout=30) | ['z','a']
         for i in [1, 2, 3]]
    f = Y(s=s) | ["d"]
EOS

NAME_B   = "PromiseB"
SCRIPT_B = <<EOS
Y:
    result = [{"a": i, "b": i*i} for i in [1,2,3]]
    format = "csv"
    title  = "#{NAME_B}"
Z:
    result = [Y() | ["result", "format", "title"] for i in [1,2,3]]
    format = "zip"
    title  = "Root#{NAME_B}"
EOS

NAME_C   = "PromiseC"
SCRIPT_C = <<EOS
Y:
    node =?
    x = 123
    res = node() | "x"
Z:
    result = Y(node=Y) | "res"
    title  = "#{NAME_C}"
EOS

NAME_D   = "PromiseD"
SCRIPT_D = <<EOS
Y:
    arg =?

Z:
    x = ERR("xxx")
    lazy = Z() | "x"
    result = Y(arg=lazy, p_title="#{NAME_D}") | "arg"
    title  = "#{NAME_D}"
EOS

NAME_E   = "PromiseE"
SCRIPT_E = <<EOS
X:
    x = 'x'*10
Z:
    result = [X() | "x" for i in [1,2,3,4,5,6]]
EOS

NAME_F   = "PromiseF"
SCRIPT_F = <<EOS
import #{NAME_E}
Z:
    result = #{NAME_E}::X() | "x"
EOS

NAME_G   = "PromiseG"
SCRIPT_G = <<EOS
U:
    result  = [123]
R:
    result = U(p_title="#{NAME_G}2") | "result"
A:
    result = R().result
V:
    result = A(p_title="#{NAME_G}") | "result"
EOS

NAME_H   = "PromiseH"
SCRIPT_H = <<EOS
Y:
    q =? nil
    a = Gemini::Helper.sleep(5) && q*q
    d = [Y(q=i) | ['a'] for i in [1, 2]]
EOS

NAME_I = "PromiseI"
SCRIPT_I = <<EOS
SLEEPER:
    secs =? nil
    a = Gemini::Helper.sleep(secs) && secs
EOS

def promise_bodies
  {
    NAME_A => SCRIPT_A,
    NAME_B => SCRIPT_B,
    NAME_C => SCRIPT_C,
    NAME_D => SCRIPT_D,
    NAME_E => SCRIPT_E,
    NAME_F => SCRIPT_F,
    NAME_G => SCRIPT_G,
    NAME_H => SCRIPT_H,
    NAME_I => SCRIPT_I,
  }
end
