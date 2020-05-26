import pygame

pygame.init()

screen = pygame.display.set_mode((480, 700))

bg = pygame.image.load("./images/background.png")
hero = pygame.image.load("./images/me1.png")
screen.blit(bg, (0, 0))
screen.blit(hero, (185, 500))
pygame.display.update()

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            print("退出游戏...")
            pygame.quit()
            exit()

