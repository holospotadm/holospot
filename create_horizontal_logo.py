from PIL import Image, ImageDraw, ImageFont
import os

# Carregar o logo original
logo_path = '/home/ubuntu/holospot/holospot_logo_cropped-Photoroom.png'
logo = Image.open(logo_path).convert('RGBA')

# Obter dimensões do logo original
logo_width, logo_height = logo.size

# Recortar apenas o símbolo (parte superior do logo, sem o texto)
symbol_height = int(logo_height * 0.68)
symbol = logo.crop((0, 0, logo_width, symbol_height))

# Tamanho do símbolo
target_symbol_height = 150
ratio = target_symbol_height / symbol.size[1]
new_symbol_width = int(symbol.size[0] * ratio)
symbol = symbol.resize((new_symbol_width, target_symbol_height), Image.Resampling.LANCZOS)

# Usar Noto Sans Bold
font_path = "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"
font_size = 70
font = ImageFont.truetype(font_path, font_size)

# Cores EXATAS extraídas do logo original
gray_color = (85, 85, 85, 255)  # Cinza para "Hol" e "Spot"
orange_color = (190, 125, 35, 255)  # Laranja dourado apenas para o "o"

# Medir cada parte do texto
hol_bbox = font.getbbox("Hol")
o_bbox = font.getbbox("o")
spot_bbox = font.getbbox("Spot")

hol_width = hol_bbox[2] - hol_bbox[0]
o_width = o_bbox[2] - o_bbox[0]
spot_width = spot_bbox[2] - spot_bbox[0]
text_height = max(hol_bbox[3] - hol_bbox[1], o_bbox[3] - o_bbox[1], spot_bbox[3] - spot_bbox[1])

total_text_width = hol_width + o_width + spot_width

# Calcular dimensões da imagem final
padding = 5
gap_between = -55  # Espaço ainda mais negativo para aproximar muito mais

final_width = symbol.size[0] + gap_between + total_text_width + padding * 2
final_height = max(symbol.size[1], text_height) + padding * 2

# Criar imagem final com fundo transparente
final_img = Image.new('RGBA', (final_width, final_height), (255, 255, 255, 0))

# Posicionar o símbolo à esquerda, centralizado verticalmente
symbol_y = (final_height - symbol.size[1]) // 2
final_img.paste(symbol, (padding, symbol_y), symbol)

# Desenhar o texto
draw = ImageDraw.Draw(final_img)

# Posição do texto (à direita do símbolo, centralizado verticalmente)
text_x = padding + symbol.size[0] + gap_between
text_y = (final_height - text_height) // 2 - hol_bbox[1]  # Ajustar pelo offset superior

# Desenhar "Hol" em cinza
draw.text((text_x, text_y), "Hol", font=font, fill=gray_color)

# Desenhar "o" em dourado (apenas este é dourado!)
draw.text((text_x + hol_width, text_y), "o", font=font, fill=orange_color)

# Desenhar "Spot" em cinza
draw.text((text_x + hol_width + o_width, text_y), "Spot", font=font, fill=gray_color)

# Salvar o resultado
output_path = '/home/ubuntu/holospot/holospot_logo_horizontal.png'
final_img.save(output_path, 'PNG')

print(f"Logo horizontal criado: {output_path}")
print(f"Dimensões: {final_img.size}")
