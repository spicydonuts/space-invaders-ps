module Handlers.Collision where

import Prelude ( (#), ($), (*), (-), (&&), (<), (>), (==)
               , bind, map, otherwise, return )

import Control.Monad.Eff ( Eff() )
import Control.Monad.ST ( ST(), STRef()
                        , modifySTRef, readSTRef )
import Data.Array ( (\\), concat, cons, filter, length, nub )
import Data.Tuple ( Tuple(..) )
import Math ( abs )
import Optic.Core ( (^.), (.~), (+~) )

import qualified Entities.Bullet as B
import qualified Entities.Game as G
import qualified Entities.Event as V
import qualified Entities.Invader as I
import Helpers.Lens ( (&) )

-- import Control.Monad.Eff.Console ( CONSOLE() )
-- import Control.Monad.Eff.Console.Unsafe ( logAny )

class Shootable a where
  isShot :: a -> B.Bullet -> Boolean

instance shootableInvader :: Shootable I.Invader where
  isShot i b =
    i^.I.status == I.Alive &&
    abs(i^.I.x - b^.B.x) < 25.0 &&
    abs(i^.I.y - b^.B.y) < 25.0

computeNewEvents :: Array V.Event -> Int -> Array V.Event
computeNewEvents currEvents invaderCount | invaderCount > 0 = cons (V.Event V.InvaderShot V.New) currEvents
                                         | otherwise = currEvents

checkInvadersShot :: forall eff g. STRef g G.Game
                  -> Eff ( st :: ST g | eff ) G.Game
checkInvadersShot gRef = do
  g <- readSTRef gRef
  let currBullets  = g ^. G.playerBullets
      currInvaders = g ^. G.invaders
      currEvents   = g ^. G.events
      collisions   = filter (\(Tuple i b) -> isShot i b) $ do
        i <- currInvaders
        b <- currBullets
        return $ Tuple i b

      -- TODO: Think about how scoring should be best handled.
      shotInvaders  = nub $ map (\(Tuple i _) -> i # I.status .~ I.Shot) collisions
      otherInvaders = currInvaders \\ shotInvaders
      deadBullets   = map (\(Tuple _ b) -> b) collisions
      newInvaders   = concat $ [otherInvaders, shotInvaders]
      newBullets    = currBullets \\ deadBullets
      newPoints     = 100 * length shotInvaders
      newEvents     = computeNewEvents currEvents $ length shotInvaders

  modifySTRef gRef (\g -> g # G.invaders .~ newInvaders
                            & G.playerBullets .~ newBullets
                            & G.score +~ newPoints
                            & G.events .~ newEvents)
