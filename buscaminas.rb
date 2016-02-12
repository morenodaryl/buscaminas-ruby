require 'rubygems'
require 'io/console'

class String
	def black; "\e[36m#{self}\e[0m" end
	def gray; "\e[37m#{self}\e[0m" end
	def bg_brown; "\e[43m#{self}\e[0m" end
	def bg_blue; "\e[44m#{self}\e[0m" end
	def bg_red; "\e[41m#{self}\e[0m" end
end

class Game
	public
	attr_accessor :filas, :columnas, :total_minas
	def initialize(f = nil, c = nil, tm = nil)
		self.filas = f
		self.columnas = c
		self.total_minas = tm
		@marcas = []
		@total_de_campos = self.filas * self.columnas unless self.filas.nil? && self.columnas.nil?
		@minas = []
		@campo = []
		@CSI ="\e["
		@estado = 'empty'
	end

	def init
		puts ''
		puts '------------------------------------------'
		puts '---------Buscaminas hecho en Ruby---------'
		puts '------------------------------------------'
		if self.filas.nil?
			print 'Cuantas filas: '
			self.filas = gets.to_i
		end
		if self.columnas.nil?
			print 'Cuantas columnas: '
			self.columnas = gets.to_i
		end
		if self.total_minas.nil?
			print 'Cuantas minas: '
			self.total_minas = gets.to_i
		end

		@total_de_campos = self.filas * self.columnas
		@actual = {fila: self.filas, columna: self.columnas}
		puts "\nTeclas para moverse: \n|A = ←|S = ↓|D = →|W = ↑| \n| Espacio=Descubrir | E=Marcar | q = Salir |\n\n"
		@estado = 'playing'
		1.upto self.total_minas do |i| # Para generar las minas random sin que se repita la posición
			salir = false
			while salir==false
				unless @minas.include? (Random.rand * @total_de_campos).ceil		
					@minas.push (Random.rand * @total_de_campos).ceil
					salir = true
				end
			end
		end
		1.upto filas do |i| # Generar los campos 
			@campo[i] = []
			1.upto columnas do |j|
				number = ((i*columnas)-columnas)+j
				if @minas.include? number
					@campo[i][j] = 'X'
				else
					@campo[i][j] = '#'
				end
				print "#"
			end
			puts ''
		end

		puts "\nMinas: #{self.total_minas}" # Pone las minas
		move :up, 3 #Metodo privado para mover
		move :left, self.columnas-1 #Metodo privado para mover el cursor
		print '#'.gray.bg_blue # Metodo de la clase String para colorear el texto
		b = '' # Tecla que preciona 
		@actual = {fila: filas, columna: columnas}

		while b != 'q'
			b = STDIN.getch
			if b == 'w' && @actual[:fila] > 1 # ARRIBA
				repint()
				@actual[:fila] = @actual[:fila] - 1 
				print "\r"
				move :up, 1
				print getprint.gray.bg_blue

			elsif b == 's' && @actual[:fila] < filas # ABAJO
				repint()
				print "\r"
				move :down, 1 
				@actual[:fila] = @actual[:fila] + 1
				print getprint.gray.bg_brown
			elsif b == 'a' && @actual[:columna] > 1 # IZQUIERDA
				repint()
				print "\r"
				move :left, @actual[:columna] - 2
				if @actual[:columna] == 2
					print "\r"
				end
				@actual[:columna] = @actual[:columna] - 1
				print getprint.gray.bg_blue
			elsif b == 'd' and @actual[:columna] < columnas # DERECHA
				repint()
				print "\r"
				move :right, @actual[:columna]
				@actual[:columna] = @actual[:columna] + 1 
				print getprint.gray.bg_brown

			elsif b == 'e'
				unless @marcas.include? [@actual[:fila], @actual[:columna]]
					# Si no existe la marca
					@marcas.push [@actual[:fila], @actual[:columna]]
				else
					# Si existe la marca
					@marcas.slice!(@marcas.find_index([@actual[:fila], @actual[:columna]]))
				end
			elsif b == ' '
				if @campo[@actual[:fila]][@actual[:columna]] == 'X'
					# Si encuentra una bomba
					print "\r"
					move :right, self.columnas
					print ' <- '
					print "\r"
					@estado = 'lose'
					repint()
					break
				else
					# Si no encuentra una bomba
					if @marcas.include? [@actual[:fila], @actual[:columna]]
						@marcas.slice!(@marcas.find_index([@actual[:fila], @actual[:columna]]))
					end
					print "\r"
					if @actual[:columna] > 1
						move(:right,@actual[:columna] - 1)
					end
					minas_alrededor = sum()
					@campo[@actual[:fila]][@actual[:columna]] = minas_alrededor.to_s
					print minas_alrededor.to_s.gray.bg_brown
				end
				if win?; break end 
			end
		end
	end

	private
	def win?
		total = 0
		1.upto self.filas do |i|
			1.upto self.columnas do |j|
				if @campo[i][j] == "#" || @campo[i][j] == "X"
					total = total + 1
				end
			end
		end
		if total == self.total_minas
			m = self.filas - @actual[:fila] + 2
			print "\r"
			move(:down, m)
			puts '*******GANASTE*******'
			true
		else
			false
		end
	end

	def move(dir,num = 1)
		l = {:up => 'A', :down => 'B', :left => 'C', :right => 'C'}
		if dir == :left || dir == :right 
			print "\r"
		end
		unless dir == :left and @actual[:columna] == 2
			$stdout.write "#{@CSI}#{num}#{l[dir]}"
		end

		if dir == :up || dir == :down
			move :right, @actual[:columna] - 1
			if @actual[:columna] == 1
				print "\r"
			end
		end

	end

	def repint
		if @estado == 'lose'
			if @actual[:fila] > 1
				move(:up,@actual[:fila] - 1) 
			end
			@campo[@actual[:fila]][@actual[:columna]] = 'X'.gray.bg_red

			print "\r"
			1.upto filas do |i|
				1.upto(columnas) do |j|
					print @campo[i][j] == 'X' ? 'X'.gray.bg_brown : @campo[i][j]
				end
				move :down, 1 
				print "\r"
			end
			if @actual[:columna] > 1
				move :right, @actual[:columna] - 1 
			end
			puts '↑'
			puts "****Perdiste****"
			gets
		else
			print "\r"
			1.upto(columnas) do |j|
				if @marcas.include? [@actual[:fila],j]
					print '#'.bg_red
				else
					print @campo[@actual[:fila]][j] == 'X' ? '#' : @campo[@actual[:fila]][j]
				end
			end
		end
	end

	def getprint
		@campo[@actual[:fila]][@actual[:columna]] == 'X' ? '#' : @campo[@actual[:fila]][@actual[:columna]]
	end

	def sum()
		sumatoria = 0
		num = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]
		num.each do |x|
			unless @campo[@actual[:fila]+x[0]].nil?
				unless @campo[@actual[:fila]+x[0]][@actual[:columna]+x[1]].nil?
					sumatoria = sumatoria + num(@campo[@actual[:fila]+x[0]][@actual[:columna]+x[1]])
				end
			end
		end
		sumatoria
	end
	def num(char)
		if char != 'X'
			0
		else
			1
		end
	end
end


juego = Game.new(10,20,15)
juego.init
