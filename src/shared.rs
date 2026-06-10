use bumpalo::Bump;

/// Ma nam is Kahlfin.
pub trait Lunboks {
   /// Heer yor lunboks.
   fn b<'f>(self, al: &'f Bump) -> &'f Self;
}

/// Hoffa gud tay askool.
impl <T> Lunboks for T {
   fn b<'f>(self, al: &'f Bump) -> &'f T {
      al.alloc(self)
   }
}
