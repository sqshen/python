import pygame
from plane_sprites import *

pygame.init()

screen = pygame.display.set_mode((480, 700))
bg = pygame.image.load("./images/background.png")
hero = pygame.image.load("./images/me1.png")
screen.blit(bg, (0, 0))
screen.blit(hero, (185, 500))
pygame.display.update()

clock = pygame.time.Clock()
hero_rec = pygame.Rect(185, 500, 102, 126)

# 创建敌机精灵
enemy = GameSprite("./images/enemy1.png")
# 创建敌机精灵组
enemy_group = pygame.sprite.Group(enemy)

while True:
    clock.tick(60)

    event_list = pygame.event.get()

    if hero_rec.y < -126:
        hero_rec.y = 700
    # elif hero_rec.y > 600:
    #     hero_rec.y = 600
    hero_rec.y -= 2
    screen.blit(bg, (0, 0))
    screen.blit(hero, hero_rec)

    # 精灵组调用update 和 draw
    enemy_group.update()
    enemy_group.draw(screen)

    pygame.display.update()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            print("退出游戏...")
            pygame.quit()
            exit()

