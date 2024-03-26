
import weavepkg/weave
  
when isMainModule:
  load("(defn Factorial X #(cond (= X 1) 1 %t #(* X (Factorial (- X 1)))))(print (Factorial 5))")
  exec()
  reportError()

