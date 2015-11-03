module Update where

import Prelude ( Unit()
               , (#), ($), (>), (/=)
               , bind, map, return, unit )

import Control.Monad.Eff ( Eff() )
import Control.Monad.ST ( ST(), STRef()
                        , modifySTRef, readSTRef )
import Data.Array ( filter )
import Optic.Core ( (^.), (.~), (+~) )

import qualified Entities.Bullet as B
import qualified Entities.Game as G
import qualified Entities.Invader as I
import qualified Handlers.Collision as C
import qualified Handlers.Motion as M

-- import Control.Monad.Eff.Console ( CONSOLE() )
-- import Control.Monad.Eff.Console.Unsafe ( logAny )

updateInvaderStatus gRef = do
  g <- readSTRef gRef
  let invaders = g ^. G.invaders
      remainingInvaders = filter (\i -> i ^. I.status /= I.Dead) invaders
      newStatus status =
        case status of
          I.Shot -> I.Dead
          _       -> status
      newInvaders = map (\i -> i # I.status .~ (newStatus $ i^.I.status)) remainingInvaders
  modifySTRef gRef (\g -> g # G.invaders .~ newInvaders)

-- TODO: Think about moving this into a different Module
--         and moving update back into Main.
removeOffscreenPlayerBullets :: forall eff g. STRef g G.Game
                             -> Eff ( st :: ST g | eff ) G.Game
removeOffscreenPlayerBullets gRef = do
  g <- readSTRef gRef
  let playerBullets = g ^. G.playerBullets
      newPlayerBullets = filter (\b -> b ^. B.y > -10.0) playerBullets
  modifySTRef gRef (\g -> g # G.playerBullets .~ newPlayerBullets)

update :: forall eff g. STRef g G.Game
       -> Eff ( st :: ST g
              -- , console :: CONSOLE
              | eff ) Unit
update gRef = do
  C.checkInvadersShot gRef
  M.movePlayerBullets gRef
  M.movePatrol gRef
  updateInvaderStatus gRef
  removeOffscreenPlayerBullets gRef
  return unit
