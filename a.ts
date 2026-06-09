// IdentContext:
//    takesFive: FVar(FVarId(1))
// TypeContext:
//    typeof FVarId(1) @== 5 -> void
PreStatement::eval               const id5 = x => { takesFive(x); return x };

   PreExpr::eval                             x => { takesFive(x); return x };
   // We encounter a lambda, let's add a new BVar
   // x -> BVar(BVarId(0))
   // Additionally, the type of x is inferred, so let's add a new metavariable
   // ?T
   // Set the type of BVarId(0) to ?T

PreStatement::eval               const id5 = x => { takesFive(x); return x };
   PreExpr::eval                             x => { takesFive(x); return x };

      // IdentContext:
      //    takesFive: FVar(FVarId(1))
      //    x: BVar(BVarId(0))
      // TypeContext:
      //    typeof FVarId(1) @== 5 -> void
      //    typeof x @== ?T
      PreBlock::eval                              { takesFive(x); return x };

         // Inherit ctx
         PreStatement::eval                         takesFive(x)
         // Look up takesFive in the context, and it resolves to FVarId(1)
         // Look up the type of FVarId(1) in the type context, learning that
         // it has Pi type 5 -> void.
         // Let's elaborate the inside before we're done.
            PreExpr::eval                                     x
            // Look up x in the ident context, resolving BVarId(0)
            // We learn that it has type ?T
         // ??? Magic ???
         // Unify 5 with ?T, emitting constraint that ?T satisfies 5

         PreStatement::eval                                       return x
         // Look up x in the ident context, resolving BVarId(0)
         // We learn that it has type ?T
         // ??? Magic ???
         // Since we encountered return, we stop elaborating the PreBlock
   // ??? Magic ???
   // Collect the constraints emitted and turn them into an expression.
   // Namely that ?T extends 5.
   emit           infer (T: Type) => (x: T): T => { takesFive(x); return x };
