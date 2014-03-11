{- |

A numeric type to manage engineering units.

Provides automatic unit conversion:

> > print $ value (1 * h + 1 * min') s        -- Time in seconds of 1 hour + 1 minute.
> 3660.0

Automatic unit reduction:

> > print $ value (20 * gpm * 10 * min') gal  -- Note the minutes cancel each other out.
> 200.0

And consistency checking:

> > print $ value (22 * mph + 3 gal) mph      -- Note that a speed (m/s) is inconsistent with a volume (m^3).
> *** Exception: Incompatible units: [M]/[S] /= [M,M,M]/[]

And defining new units is easy:

> -- | Millimeters, a measure of distance.
> mm :: Value
> mm = 0.001 * m

> -- | Joules, a measure of energy.
> j :: Value
> j = n * m

-}
module Data.EngineeringUnits
  ( Value
  , value
  -- * Distance
  , m    
  , cm   
  , in'  
  , ft   
  , mi   
  -- * Area
  , cm2  
  , in2  
  -- * Volume
  , cm3  
  , in3  
  , gal  
  -- * Mass
  , kg   
  -- * Force
  , n    
  , lbs  
  -- * Rotation
  , rev  
  -- * Speed
  , mph  
  -- * Rotational Rate
  , rpm  
  -- * Time
  , s    
  , min' 
  , h
  -- * Power
  , hp   
  , w    
  , kw   
  -- * Pressure
  , psi  
  , bar
  -- * Flow
  , gpm  
  -- * Other
  , s2   
  , radsPerRev
  ) where

import Data.List

-- | The base units for distance, time, mass, and revolutions.
data Unit = M | S | Kg | Rev deriving (Eq, Ord, Show)

-- | A value is a number and its associated units.
data Value = Value Double [Unit] [Unit] deriving (Show, Eq, Ord)

instance Num Value where
  a@(Value aV _ _) + b@(Value bV _ _) = same a b $ aV + bV
  a@(Value aV _ _) - b@(Value bV _ _) = same a b $ aV - bV
  Value aV aN aD * Value bV bN bD = normalize $ Value (aV * bV) (aN ++ bN) (aD ++ bD)
  fromInteger a = Value (fromIntegral a) [] []
  negate (Value v n d) = Value (negate v) n d
  abs    (Value v n d) = Value (abs    v) n d
  signum (Value v n d) = Value (signum v) n d

instance Fractional Value where
  Value aV aN aD / Value bV bN bD = normalize $ Value (aV / bV) (aN ++ bD) (aD ++ bN)
  recip (Value v n d) = Value (recip v) d n
  fromRational a = Value (fromRational a) [] []

instance Floating Value where
  pi    = Value pi [] []
  exp   = error "Not supported yet for Value: exp  "
  log   = error "Not supported yet for Value: log  "
  sin   = error "Not supported yet for Value: sin  "
  cos   = error "Not supported yet for Value: cos  "
  sinh  = error "Not supported yet for Value: sinh "
  cosh  = error "Not supported yet for Value: cosh "
  asin  = error "Not supported yet for Value: asin "
  acos  = error "Not supported yet for Value: acos "
  atan  = error "Not supported yet for Value: atan "
  asinh = error "Not supported yet for Value: asinh"
  acosh = error "Not supported yet for Value: acosh"
  atanh = error "Not supported yet for Value: atanh"

-- | Normalize a value, i.e. simplify and sort units.
normalize :: Value -> Value
normalize a@(Value _ n d) = order $ reduce (n ++ d) a
  where
  reduce :: [Unit] -> Value -> Value
  reduce [] a = a
  reduce (a : rest) (Value v n d)
    | elem a n && elem a d = reduce rest $ Value v (delete a n) (delete a d)
    | otherwise            = reduce rest $ Value v n d
  order :: Value -> Value
  order (Value v n d) = Value v (sort n) (sort d)

-- | Create a value if two units are compatible.
same :: Value -> Value -> Double -> Value
same (Value _ aN aD) (Value _ bN bD) v
  | aN == bN && aD == bD = Value v aN aD
  | otherwise = error $ "Incompatible units: " ++ show aN ++ "/" ++ show aD ++ " /= " ++ show bN ++ "/" ++ show bD

-- | Extract a value in the given units.
value :: Value -> Value -> Double
value val@(Value v _ _) units@(Value k _ _) = result
  where
  Value result _ _ = same val units $ v / k

-- | Meters.
m    = Value 1 [M]   []
-- | Seconds.
s    = Value 1 [S]   []
-- | Kilograms.
kg   = Value 1 [Kg]  []
-- | Revolutions.
rev  = Value 1 [Rev] []
-- | Seconds ^ 2.
s2   = s * s
-- | Centimeters.
cm   = 0.01 * m
-- | Centimeters ^ 2.
cm2  = cm * cm
-- | Centimeters ^ 3.
cm3  = cm * cm * cm
-- | Inches.
in'  = 2.54 * cm
-- | Inches ^ 2.
in2  = in' * in'
-- | Inches ^ 3.
in3  = in' * in' * in'
-- | Feet.
ft   = 12 * in'
-- | Minutes.
min' = 60 * s
-- | Hours.
h    = 60 * min'
-- | Newtons.
n    = kg * m / s2
-- | Pounds.
lbs  = 4.448222 * n
-- | Miles.
mi   = 5280 * ft
-- | Gallons.
gal  = 231 * in3
-- | Horsepower.
hp   = 33000 * ft * lbs / min'
-- | Watts.
w    = 0.00134102209 * hp
-- | Kilowatts.
kw   = 1000 * w
-- | Pounds per inch ^ 2.
psi  = lbs / in2
-- | Bar.
bar  = 14.5037738 * psi
-- | Miles per hour.
mph  = mi / h
-- | Revolutions per minute.
rpm  = rev / min'
-- | Gallons per minute.
gpm  = gal / min'
-- | Radians per revolution: 2 * pi / rev
radsPerRev = 2 * pi / rev

