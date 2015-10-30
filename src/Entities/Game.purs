module Entities.Game where

import Prelude ( bind, flip, return, unit
               , (#), ($), (*) )

import Control.Monad.Eff ( Eff() )
import Control.Monad.ST ( ST(), STRef()
                        , modifySTRef, readSTRef )
import Data.Array ( cons )
import Data.Date ( Now()
                 , nowEpochMilliseconds )
import Data.Time ( Milliseconds() )
import Graphics.Canvas ( Canvas()
                       , CanvasImageSource() )
import Optic.Core ( Lens()
                  , (..), (^.), (%~)
                  , lens )

import qualified Entities.Bullet as B
import qualified Entities.Enemies as E
import qualified Entities.Invader as I
import qualified Entities.Player as P
import qualified Entities.Sprites as S

data Status = GameOver
            | Playing
            | Waiting

data Game = Game
  { w :: Number
  , h :: Number
  , startTime :: Milliseconds
  , status :: Status
  , score :: Int
  , lives :: Int
  , player :: P.Player
  , playerBullets :: Array B.Bullet
  , sprites :: S.Sprites
  , enemies :: E.Enemies
  }

w = lens (\(Game g) -> g.w)
         (\(Game g) w' -> Game (g { w = w' }))
h = lens (\(Game g) -> g.h)
         (\(Game g) h' -> Game (g { h = h' }))
startTime = lens (\(Game g) -> g.startTime)
                 (\(Game g) startTime' -> Game (g { startTime = startTime' }))
lives = lens (\(Game g) -> g.lives)
             (\(Game g) lives' -> Game (g { lives = lives' }))
player = lens (\(Game g) -> g.player)
              (\(Game g) player' -> Game (g { player = player' }))
playerBullets = lens (\(Game g) -> g.playerBullets)
                     (\(Game g) playerBullets' -> Game (g { playerBullets = playerBullets' }))
sprites = lens (\(Game g) -> g.sprites)
               (\(Game g) sprites' -> Game (g { sprites = sprites' }))
enemies = lens (\(Game g) -> g.enemies)
               (\(Game g) enemies' -> Game (g { enemies = enemies' }))

playerX :: Lens Game Game Number Number
playerX = player .. P.x
playerY :: Lens Game Game Number Number
playerY = player .. P.y
invaders :: Lens Game Game (Array I.Invader) (Array I.Invader)
invaders = enemies .. E.invaders
patrolDirection :: Lens Game Game E.Direction E.Direction
patrolDirection = enemies .. E.direction
patrolDx :: Lens Game Game Number Number
patrolDx = enemies .. E.dx

lifeSprite :: Lens Game Game CanvasImageSource CanvasImageSource
lifeSprite = sprites .. S.lives
playerSprite :: Lens Game Game CanvasImageSource CanvasImageSource
playerSprite = sprites .. S.player
playerBulletSprite :: Lens Game Game CanvasImageSource CanvasImageSource
playerBulletSprite = sprites .. S.playerBullet
invaderSprites :: Lens Game Game (Array CanvasImageSource) (Array CanvasImageSource)
invaderSprites = sprites .. S.invader

makeGame :: forall eff. Number
         -> Number
         -> Eff ( canvas :: Canvas
                , now :: Now | eff) Game
makeGame w h = do
  let player = P.makePlayer (0.5*w) (0.9*h)
  sprites <- S.loadSprites
  startTime <- nowEpochMilliseconds
  return $ Game
    { w:         w
    , h:         h
    , startTime: startTime
    , status:    Waiting
    , score:     0
    , lives:     3
    , player:    player
    , playerBullets: []
    , sprites: sprites
    , enemies: E.makeRegularLevel
    }

createPlayerBullet :: forall g eff. STRef g Game
                   -> Eff ( st :: ST g | eff ) Game
createPlayerBullet gRef = do
  g <- readSTRef gRef
  let newPlayerBullet = B.makePlayerBullet (g ^. playerX) (g ^. playerY)
  modifySTRef gRef (\g -> g # playerBullets %~ (cons newPlayerBullet))
