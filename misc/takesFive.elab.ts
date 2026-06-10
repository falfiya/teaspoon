declare function takesFive(x: 5);
const id5 = a => {takesFive(a); return a};

// IdentContext:
//    takesFive: FVar(FVarId(1))
// TypeContext:
//    typeof FVarId(1) @== 5 -> void
PreStatement::eval               const id5 = x => { takesFive(x); return x };

   PreExpr::eval                             x => { takesFive(x); return x };
   // We encounter a lambda, let's add a new BVar
   // x -> BVar(BVarId(0))
   // Additionally, the type of x is inferred, so let's add a new metavariable
   // MVar(MVarId(0)), also known as ?T
   // Set the type of BVarId(0) to ?T

PreStatement::eval               const id5 = x => { takesFive(x); return x };
   PreExpr::eval                             x => { takesFive(x); return x };

      // IdentContext:
      //    takesFive: FVar(FVarId(1))
      //    x: BVar(BVarId(0))
      // TypeContext:
      //    typeof FVar(FVarId(1)) @== 5 -> void
      //    typeof BVar(BVarId(0)) @== MVar(MVarId(0))
      PreBlock::eval                              { takesFive(x); return x };

         // Inherit ctx
         PreStatement::eval                         takesFive(x)
         // Look up takesFive in the context, and it resolves to FVarId(1)
         // Look up the type of FVarId(1) in the type context.
            TypeContext::query(FVar(FVarId(1)))
            // The only facts in the type context that contain this are:
            //    1. typeof FVar(FVarId(1)) @== 5 -> void
            // Collect the facts to get 5 -> void
         // Good, it's a function type. We can keep going.
         // In elaborating a function call, we want to ensure that the arguments
         // to the function call have compatible types with the parameters.
         // Therefore, let us elab the argument.
            PreExpr::eval                                     x
            // Look up x in the ident context, resolving BVarId(0)
            // We learn that it has type MVar(MVarId(0)) which is ?T
            // Emit a constraint:
            MVar(MVarId(0)) extends 5
            // IT'S STRONGLY WORTH NOTING THAT 5 is an easy constraint.

         PreStatement::eval                                       return x
         // Look up x in the ident context, resolving BVarId(0)
         // We learn that it has type MVar(MVarId(0))
         // PreBlocks are elaborated until they see return.
         // Look up x, etc. We are returning ?T which is MVar(MVarId(0))
      TypeContext::query(MVar(MVarId(0)))
      // 1. typeof FVar(FVarId(0)) @== 5 -> void
   // Collect the constraints.
   // Namely that ?T extends 5.
   infer (T: Liquid (t: Type), t extends 5) => (x: T): T => {takesFive(a); return a}
   // Simplify
   infer (T: 5) => (x: T): T => {takesFive(a); return a};
   // Simplify (due to singleton type)
   (a: 5): 5 => {takesFive(a); return a};
