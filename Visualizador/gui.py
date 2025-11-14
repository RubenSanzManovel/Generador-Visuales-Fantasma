# ============================================================================
# GUI.PY - INTERFAZ GRÁFICA DE USUARIO
# ============================================================================
# Pantalla de inicio con botones para seleccionar el modo de visualización
# ============================================================================

import pygame
import config
from typing import Optional, Tuple, Dict

class Button:
    """Botón interactivo con efecto hover"""
    
    def __init__(self, x: int, y: int, width: int, height: int, text: str, 
                 color: Tuple[int, int, int], hover_color: Tuple[int, int, int]):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.color = color
        self.hover_color = hover_color
        self.is_hovered = False
    
    def draw(self, screen: pygame.Surface, font: pygame.font.Font):
        """Dibuja el botón en la pantalla"""
        current_color = self.hover_color if self.is_hovered else self.color
        
        # Sombra del botón
        shadow_rect = self.rect.copy()
        shadow_rect.x += 5
        shadow_rect.y += 5
        pygame.draw.rect(screen, (0, 0, 0, 100), shadow_rect, border_radius=10)
        
        # Botón principal
        pygame.draw.rect(screen, current_color, self.rect, border_radius=10)
        
        # Borde brillante
        border_color = (255, 255, 255) if self.is_hovered else (180, 180, 180)
        pygame.draw.rect(screen, border_color, self.rect, 3, border_radius=10)
        
        # Texto con sombra
        text_shadow = font.render(self.text, True, (0, 0, 0))
        text_shadow_rect = text_shadow.get_rect(center=(self.rect.centerx + 2, self.rect.centery + 2))
        screen.blit(text_shadow, text_shadow_rect)
        
        text_surface = font.render(self.text, True, (255, 255, 255))
        text_rect = text_surface.get_rect(center=self.rect.center)
        screen.blit(text_surface, text_rect)
    
    def handle_event(self, event: pygame.event.Event) -> bool:
        """Maneja eventos del mouse. Retorna True si se hace clic en el botón"""
        if event.type == pygame.MOUSEMOTION:
            self.is_hovered = self.rect.collidepoint(event.pos)
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.is_hovered:
                return True
        return False


class GUI:
    """Interfaz gráfica de inicio para seleccionar modo de visualización"""
    
    def __init__(self):
        """Inicializa la GUI"""
        pygame.init()
        
        # Obtener resolución de pantalla completa
        display_info = pygame.display.Info()
        self.screen_width = display_info.current_w
        self.screen_height = display_info.current_h
        
        # Crear ventana maximizada sin bordes (mejor que FULLSCREEN para alt+tab)
        self.screen = pygame.display.set_mode(
            (self.screen_width, self.screen_height),
            pygame.NOFRAME
        )
        pygame.display.set_caption("Visualizador de Música")
        
        # Mantener cursor visible en la GUI
        pygame.mouse.set_visible(True)
        
        # Fuentes
        self.title_font = pygame.font.Font(None, 100)
        self.button_font = pygame.font.Font(None, 50)
        self.info_font = pygame.font.Font(None, 35)
        
        # Estado
        self.selected_mode: Optional[str] = None
        self.selected_pattern: Optional[int] = None
        self.selected_beats: Optional[int] = None
        
        # Gradiente de fondo
        self.bg_gradient = self._create_gradient()
    
    def _create_gradient(self) -> pygame.Surface:
        """Crea un gradiente de fondo animado"""
        gradient = pygame.Surface((self.screen_width, self.screen_height))
        for y in range(self.screen_height):
            ratio = y / self.screen_height
            r = int(15 + (40 - 15) * ratio)
            g = int(5 + (25 - 5) * ratio)
            b = int(35 + (60 - 35) * ratio)
            pygame.draw.line(gradient, (r, g, b), (0, y), (self.screen_width, y))
        return gradient
    
    def show_main_menu(self) -> Dict:
        """
        Muestra el menú principal y retorna la configuración seleccionada.
        Retorna un diccionario con: {'mode': str, 'pattern': int, 'beats': int}
        """
        # Calcular posiciones centradas
        center_x = self.screen_width // 2
        center_y = self.screen_height // 2
        button_width = 400
        button_height = 80
        spacing = 100
        
        # Crear botones
        buttons = [
            Button(center_x - button_width // 2, center_y - spacing * 2, 
                   button_width, button_height, "MODO ADMIN", 
                   (100, 50, 150), (150, 80, 200)),
            Button(center_x - button_width // 2, center_y - spacing, 
                   button_width, button_height, "MODO ORDER", 
                   (50, 100, 150), (80, 150, 200)),
            Button(center_x - button_width // 2, center_y, 
                   button_width, button_height, "MODO RANDOM", 
                   (150, 50, 100), (200, 80, 150)),
            Button(center_x - button_width // 2, int(center_y + spacing * 1.5), 
                   button_width, button_height, "SALIR", 
                   (150, 50, 50), (200, 80, 80)),
        ]
        
        clock = pygame.time.Clock()
        running = True
        
        # Animar el fondo
        time_offset = 0
        
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return {'mode': 'exit'}
                
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        return {'mode': 'exit'}
                
                # Prevenir bloqueos al cambiar ventanas
                if event.type == pygame.WINDOWFOCUSGAINED:
                    pass
                elif event.type == pygame.WINDOWFOCUSLOST:
                    pass
                
                # Manejar clics en botones
                for i, button in enumerate(buttons):
                    if button.handle_event(event):
                        if i == 0:  # ADMIN
                            return self._show_admin_menu()
                        elif i == 1:  # ORDER
                            return self._show_order_menu()
                        elif i == 2:  # RANDOM
                            return {'mode': 'random', 'pattern': 0, 'beats': 0}
                        elif i == 3:  # SALIR
                            return {'mode': 'exit'}
            
            time_offset += 0.01
            
            # Dibujar
            self.screen.blit(self.bg_gradient, (0, 0))
            
            # Título
            title = self.title_font.render("🎵 VISUALIZADOR MUSICAL 🎵", True, (255, 255, 255))
            title_rect = title.get_rect(center=(center_x, center_y - spacing * 3))
            self.screen.blit(title, title_rect)
            
            # Subtítulo
            subtitle = self.info_font.render("Selecciona un modo de visualización", True, (200, 200, 200))
            subtitle_rect = subtitle.get_rect(center=(center_x, center_y - spacing * 2.5))
            self.screen.blit(subtitle, subtitle_rect)
            
            # Botones
            for button in buttons:
                button.draw(self.screen, self.button_font)
            
            pygame.display.flip()
            clock.tick(60)
        
        return {'mode': 'exit'}
    
    def _show_admin_menu(self) -> Dict:
        """Menú para seleccionar patrón específico en modo admin"""
        center_x = self.screen_width // 2
        center_y = self.screen_height // 2
        
        # Crear botones de patrones en grid - ajustado para que quepa todo
        patterns_per_row = 8
        button_size = 90
        spacing = 15
        total_rows = (config.TOTAL_PATTERNS + patterns_per_row - 1) // patterns_per_row
        
        # Calcular tamaño del grid
        grid_width = patterns_per_row * (button_size + spacing) - spacing
        grid_height = total_rows * (button_size + spacing) - spacing
        
        # Centrar el grid verticalmente considerando el título
        start_x = center_x - grid_width // 2
        start_y = 220  # Espacio desde arriba para el título
        
        buttons = []
        for i in range(config.TOTAL_PATTERNS):
            row = i // patterns_per_row
            col = i % patterns_per_row
            x = start_x + col * (button_size + spacing)
            y = start_y + row * (button_size + spacing)
            btn = Button(x, y, button_size, button_size, str(i), 
                        (80, 80, 120), (120, 120, 180))
            buttons.append(btn)
        
        # Botón volver
        back_button = Button(50, self.screen_height - 120, 200, 70, "← VOLVER", 
                            (80, 80, 80), (120, 120, 120))
        
        clock = pygame.time.Clock()
        running = True
        
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return {'mode': 'exit'}
                
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        return self.show_main_menu()
                
                # Prevenir bloqueos
                if event.type in (pygame.WINDOWFOCUSGAINED, pygame.WINDOWFOCUSLOST):
                    pass
                
                # Botón volver
                if back_button.handle_event(event):
                    return self.show_main_menu()
                
                # Botones de patrones
                for i, button in enumerate(buttons):
                    if button.handle_event(event):
                        return {'mode': 'admin', 'pattern': i, 'beats': 0}
            
            # Dibujar
            self.screen.blit(self.bg_gradient, (0, 0))
            
            # Título
            title = self.title_font.render("MODO ADMIN", True, (255, 255, 255))
            title_rect = title.get_rect(center=(center_x, 80))
            self.screen.blit(title, title_rect)
            
            subtitle = self.info_font.render("Selecciona un patrón visual (0-35)", True, (200, 200, 200))
            subtitle_rect = subtitle.get_rect(center=(center_x, 150))
            self.screen.blit(subtitle, subtitle_rect)
            
            # Botones
            for button in buttons:
                button.draw(self.screen, self.button_font)
            
            back_button.draw(self.screen, self.button_font)
            
            pygame.display.flip()
            clock.tick(60)
        
        return {'mode': 'exit'}
    
    def _show_order_menu(self) -> Dict:
        """Menú para configurar beats en modo order"""
        center_x = self.screen_width // 2
        center_y = self.screen_height // 2
        
        button_width = 300
        button_height = 80
        spacing = 20
        
        # Opciones de beats
        beat_options = [8, 16, 24, 32, 48, 64]
        buttons = []
        
        for i, beats in enumerate(beat_options):
            row = i // 3
            col = i % 3
            x = center_x - (3 * (button_width + spacing)) // 2 + col * (button_width + spacing)
            y = center_y - 100 + row * (button_height + spacing)
            btn = Button(x, y, button_width, button_height, f"{beats} BEATS", 
                        (60, 100, 140), (90, 140, 190))
            buttons.append((btn, beats))
        
        # Botón volver
        back_button = Button(50, self.screen_height - 120, 200, 70, "← VOLVER", 
                            (80, 80, 80), (120, 120, 120))
        
        clock = pygame.time.Clock()
        running = True
        
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return {'mode': 'exit'}
                
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        return self.show_main_menu()
                
                # Prevenir bloqueos
                if event.type in (pygame.WINDOWFOCUSGAINED, pygame.WINDOWFOCUSLOST):
                    pass
                
                # Botón volver
                if back_button.handle_event(event):
                    return self.show_main_menu()
                
                # Botones de beats
                for button, beats in buttons:
                    if button.handle_event(event):
                        return {'mode': 'order', 'pattern': 0, 'beats': beats}
            
            # Dibujar
            self.screen.blit(self.bg_gradient, (0, 0))
            
            # Título
            title = self.title_font.render("MODO ORDER", True, (255, 255, 255))
            title_rect = title.get_rect(center=(center_x, 150))
            self.screen.blit(title, title_rect)
            
            subtitle = self.info_font.render("Selecciona los beats para cambiar de patrón", True, (200, 200, 200))
            subtitle_rect = subtitle.get_rect(center=(center_x, 240))
            self.screen.blit(subtitle, subtitle_rect)
            
            # Botones
            for button, _ in buttons:
                button.draw(self.screen, self.button_font)
            
            back_button.draw(self.screen, self.button_font)
            
            pygame.display.flip()
            clock.tick(60)
        
        return {'mode': 'exit'}
    
    def close(self):
        """Cierra la GUI"""
        pygame.quit()
