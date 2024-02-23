# Deriving SAL24 from TRAC T64

SAL24 ("Small Applicative Language 2024") is a LISP-like TRAC dialect.


## Overview of TRAC algorithm

## Syntatic transformation

### Step 0: Global escaping character

To open up a fallback method for directly representing the "special characters" the character `@` is choosen to be the **global escape character**; this means that when this character occurs, the next character is appended to the right-end of the neutral string buffer no matter which character it is.

### Step 1: Removing `##()`

If you don't know, the difference between `#()` and `##()` is that the result of the former would be evaluated again while the latter would only get evaluated *once*. We rarely need the latter so 

### Step 2: Removing `#`

### Step 3: Adding `#` back in

But instead of active call it's used to be the "escape prefix". [], so `#(dss)` in SAL24 would be equivalent to `(dss)` in TRAC T64.

### Step 4: Replacing `,` with whitespaces

In TRAC T64 non-newline whitespaces are significant; we'll use string literals for those. 

### Step 5: Ignore any whitespaces between terms

If you don't know already, in TRAC T64 non-newline whitespaces is treated as a part of normal text; this means the following two lines would output differently:

```
#(ps,some str)'
#(ps, some str)'
```

The first line would output `some str`, but the second line would output ` some str`. 

### Step 6: Default call

In TRAC T64, if you want to call a string you must use the `cl` primitive. In this step we allow

### Step 7: Removing meta character

When the parentheses are fully balanced, it's treated as if a meta character has already been read.

### The result of syntatic transformation

This is factorial in TRAC:

```
#(ds,Factorial,(#(eq,X,1,1,(#(ml,X,#(cl,Factorial,#(su,X,1)))))))'
#(ss,Factorial,X)'
#(cl,Factorial,5)'
```

This is factorial in our basic SAL24:

```
(ds Factorial #(eq X 1 1 #(ml X (Factorial (su x 1)))))))
(ss Factorial X)
(Factorial 5)
```

## Semantic transformation

### Step 8: Fixing `ds`

```
(defn Factorial X
  #(eq X 1
      1
      #(ml X (Factorial (su x 1)))))))
(Factorial 5)
```

### Step 9: Better primitives

+ Remove `ss` (since we combined `ss` and `ds` as `defn`)
+ Add `if` and change `eq` to boolean-value-providing only.
+ Remove 

```
(defn Factorial X
  #(if (eq X 1)
       1
       #(* X (Factorial (- x 1)))))))
(Factorial 5)
```


