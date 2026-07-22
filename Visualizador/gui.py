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
        
        # Configurar DPI awareness para Windows para que detecte la resolución física nativa real
        import ctypes
        try:
            ctypes.windll.shcore.SetProcessDpiAwareness(2)
        except Exception:
            try:
                ctypes.windll.user32.SetProcessDPIAware()
            except Exception:
                pass
                
        try:
            # Ventana sin bordes (NOFRAME) para evitar que Windows minimice la app al perder foco (ej. escribir en el chat)
            self.screen = pygame.display.set_mode((0, 0), pygame.NOFRAME)
        except pygame.error as e:
            print(f"[!] No se pudo iniciar la GUI en modo sin bordes: {e}. Probando modo ventana...")
            self.screen = pygame.display.set_mode((1280, 720))
            
        self.screen_width, self.screen_height = self.screen.get_size()
        pygame.display.set_caption("Visualizador de Música")
        
        # Mantener cursor visible en la GUI
        pygame.mouse.set_visible(True)
        
        # Fuentes proporcionales al alto de la pantalla actual
        self.title_font = pygame.font.Font(None, int(self.screen_height * 0.092))
        self.button_font = pygame.font.Font(None, int(self.screen_height * 0.046))
        self.info_font = pygame.font.Font(None, int(self.screen_height * 0.032))
        
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
        
        # Dimensiones de botones escaladas proporcionalmente
        button_width = int(self.screen_width * 0.208)  # ~400 en 1920
        button_width = max(300, min(500, button_width))
        button_height = int(self.screen_height * 0.074) # ~80 en 1080
        button_height = max(50, min(100, button_height))
        spacing = int(self.screen_height * 0.092)       # ~100 en 1080
        
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
        
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return {'mode': 'exit'}
                
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        return {'mode': 'exit'}
                
                # Prevenir bloqueos al cambiar ventanas
                if event.type in (pygame.WINDOWFOCUSGAINED, pygame.WINDOWFOCUSLOST):
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
        """Menú para seleccionar patrón específico en modo admin con soporte de scrollbar y rueda del mouse"""
        center_x = self.screen_width // 2
        
        # Crear botones de patrones en grid escalados dinámicamente
        patterns_per_row = 8
        button_size = int(self.screen_height * 0.083) # ~90 en 1080
        spacing = int(self.screen_height * 0.014)     # ~15 en 1080
        total_rows = (config.TOTAL_PATTERNS + patterns_per_row - 1) // patterns_per_row
        
        # Calcular tamaño del grid
        grid_width = patterns_per_row * (button_size + spacing) - spacing
        content_height = total_rows * (button_size + spacing) - spacing
        
        # Centrar el grid horizontalmente
        start_x = center_x - grid_width // 2
        start_y = int(self.screen_height * 0.204)     # ~220 en 1080
        
        # Viewport visible
        viewport_top = int(self.screen_height * 0.194) # ~210 en 1080
        viewport_height = self.screen_height - viewport_top - int(self.screen_height * 0.139) # ~150 desde abajo en 1080
        viewport_bottom = viewport_top + viewport_height
        visible_height = viewport_height
        
        buttons = []
        for i in range(config.TOTAL_PATTERNS):
            row = i // patterns_per_row
            col = i % patterns_per_row
            x = start_x + col * (button_size + spacing)
            y = start_y + row * (button_size + spacing)
            btn = Button(x, y, button_size, button_size, str(i), 
                        (80, 80, 120), (120, 120, 180))
            buttons.append(btn)
        
        # Configuración del Slider/Scrollbar
        scroll_y = 0.0
        max_scroll_y = float(max(0, content_height - visible_height))
        dragging_slider = False
        drag_offset_y = 0
        
        slider_x = min(self.screen_width - int(self.screen_width * 0.018), start_x + grid_width + int(self.screen_width * 0.015))
        slider_y = viewport_top
        slider_height = viewport_height
        slider_width = 15
        
        # Botón volver escalado
        back_btn_w = int(self.screen_width * 0.104) # ~200 en 1920
        back_btn_h = int(self.screen_height * 0.065) # ~70 en 1080
        back_button = Button(int(self.screen_width * 0.026), self.screen_height - back_btn_h - int(self.screen_height * 0.046), 
                             back_btn_w, back_btn_h, "← VOLVER", 
                             (80, 80, 80), (120, 120, 120))
        
        clock = pygame.time.Clock()
        running = True
        
        while running:
            # Actualizar posiciones de colisión de los botones respecto al scroll
            for i, button in enumerate(buttons):
                row = i // patterns_per_row
                button.rect.y = start_y + row * (button_size + spacing) - int(scroll_y)
                
            mouse_pos = pygame.mouse.get_pos()
            
            # Calcular dimensiones del tirador (handle)
            handle_height = max(40, int(slider_height * (visible_height / max(1.0, float(content_height)))))
            handle_y = slider_y + int((slider_height - handle_height) * (scroll_y / max(1.0, max_scroll_y)))
            
            handle_rect = pygame.Rect(slider_x, handle_y, slider_width, handle_height)
            track_rect = pygame.Rect(slider_x, slider_y, slider_width, slider_height)
            handle_hover = handle_rect.collidepoint(mouse_pos)
            
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return {'mode': 'exit'}
                
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        return self.show_main_menu()
                
                # Prevenir bloqueos
                if event.type in (pygame.WINDOWFOCUSGAINED, pygame.WINDOWFOCUSLOST):
                    pass
                
                # Scroll con rueda de ratón / gestos touchpad
                if event.type == pygame.MOUSEWHEEL:
                    if max_scroll_y > 0:
                        scroll_y = max(0.0, min(max_scroll_y, scroll_y - event.y * 60.0))
                
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 4:  # Rueda arriba
                        scroll_y = max(0.0, scroll_y - 60.0)
                    elif event.button == 5:  # Rueda abajo
                        scroll_y = min(max_scroll_y, scroll_y + 60.0)
                    elif event.button == 1 and max_scroll_y > 0:
                        if handle_rect.collidepoint(event.pos):
                            dragging_slider = True
                            drag_offset_y = event.pos[1] - handle_y
                        elif track_rect.collidepoint(event.pos):
                            if slider_height > handle_height:
                                new_h_y = event.pos[1] - handle_height // 2
                                new_h_y = max(slider_y, min(new_h_y, slider_y + slider_height - handle_height))
                                scroll_y = ((new_h_y - slider_y) / float(slider_height - handle_height)) * max_scroll_y
                                dragging_slider = True
                                drag_offset_y = handle_height // 2
                
                if event.type == pygame.MOUSEBUTTONUP:
                    if event.button == 1:
                        dragging_slider = False
                
                if event.type == pygame.MOUSEMOTION and dragging_slider and max_scroll_y > 0:
                    new_h_y = event.pos[1] - drag_offset_y
                    new_h_y = max(slider_y, min(new_h_y, slider_y + slider_height - handle_height))
                    if slider_height > handle_height:
                        scroll_y = ((new_h_y - slider_y) / float(slider_height - handle_height)) * max_scroll_y
                    else:
                        scroll_y = 0.0
                
                # Botón volver
                if back_button.handle_event(event):
                    return self.show_main_menu()
                
                # Botones de patrones (solo cliqueables si están en la región visible del viewport)
                for i, button in enumerate(buttons):
                    if button.rect.y + button_size >= viewport_top and button.rect.y <= viewport_bottom:
                        if button.handle_event(event):
                            return {'mode': 'admin', 'pattern': i, 'beats': 0}
            
            # Dibujar
            self.screen.blit(self.bg_gradient, (0, 0))
            
            # Título
            title = self.title_font.render("MODO ADMIN", True, (255, 255, 255))
            title_rect = title.get_rect(center=(center_x, int(self.screen_height * 0.074))) # ~80 en 1080
            self.screen.blit(title, title_rect)
            
            subtitle = self.info_font.render(f"Selecciona un patrón visual (0-{config.TOTAL_PATTERNS-1})", True, (200, 200, 200))
            subtitle_rect = subtitle.get_rect(center=(center_x, int(self.screen_height * 0.139))) # ~150 en 1080
            self.screen.blit(subtitle, subtitle_rect)
            
            # Dibujar botones recortados (clipping) en el viewport
            self.screen.set_clip(pygame.Rect(0, viewport_top - 5, self.screen_width, viewport_height + 10))
            for button in buttons:
                if button.rect.y + button_size >= viewport_top - 10 and button.rect.y <= viewport_bottom + 10:
                    button.draw(self.screen, self.button_font)
            self.screen.set_clip(None) # Restaurar dibujo a pantalla completa
            
            back_button.draw(self.screen, self.button_font)
            
            # Dibujar la Scrollbar si el contenido supera la pantalla
            if max_scroll_y > 0:
                pygame.draw.rect(self.screen, (40, 40, 60), track_rect, border_radius=7)
                pygame.draw.rect(self.screen, (60, 60, 90), track_rect, 2, border_radius=7)
                
                h_color = (180, 180, 250) if (handle_hover or dragging_slider) else (110, 110, 170)
                pygame.draw.rect(self.screen, h_color, handle_rect, border_radius=7)
                pygame.draw.rect(self.screen, (255, 255, 255), handle_rect, 2, border_radius=7)
            
            pygame.display.flip()
            clock.tick(60)
        
        return {'mode': 'exit'}
    
    def _show_order_menu(self) -> Dict:
        """Menú para configurar beats en modo order"""
        center_x = self.screen_width // 2
        center_y = self.screen_height // 2
        
        button_width = int(self.screen_width * 0.156) # ~300 en 1920
        button_height = int(self.screen_height * 0.074) # ~80 en 1080
        spacing = int(self.screen_height * 0.018) # ~20 en 1080
        
        # Opciones de beats
        beat_options = [8, 16, 24, 32, 48, 64]
        buttons = []
        
        for i, beats in enumerate(beat_options):
            row = i // 3
            col = i % 3
            x = center_x - (3 * (button_width + spacing)) // 2 + col * (button_width + spacing)
            y = center_y - int(self.screen_height * 0.092) + row * (button_height + spacing)
            btn = Button(x, y, button_width, button_height, f"{beats} BEATS", 
                        (60, 100, 140), (90, 140, 190))
            buttons.append((btn, beats))
        
        # Botón volver escalado
        back_btn_w = int(self.screen_width * 0.104) # ~200 en 1920
        back_btn_h = int(self.screen_height * 0.065) # ~70 en 1080
        back_button = Button(int(self.screen_width * 0.026), self.screen_height - back_btn_h - int(self.screen_height * 0.046), 
                             back_btn_w, back_btn_h, "← VOLVER", 
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
            title_rect = title.get_rect(center=(center_x, int(self.screen_height * 0.139))) # ~150 en 1080
            self.screen.blit(title, title_rect)
            
            subtitle = self.info_font.render("Selecciona los beats para cambiar de patrón", True, (200, 200, 200))
            subtitle_rect = subtitle.get_rect(center=(center_x, int(self.screen_height * 0.222))) # ~240 en 1080
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
