import enum, os, sys
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame
import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from cocotb.decorators import coroutine
# from cocotb.monitors import Monitor
# from cocotb.scoreboard import Scoreboard


class connector_type(enum.Enum):
	common_anode = 0
	common_cathode = 1

class avalon_interface(object):
	signals = [ 'read', 'readdata', 'write', 'writedata', 'address',
			'reset_n', 'clk', 'reset' ]
	def __init__(self, dut):
		self._dut = dut
		for signal in self.signals:
			if hasattr(dut, signal):
				dut._log.info(f'added signal {signal}')
				setattr(self, f'_{signal}', getattr(dut, signal))
			else:
				dut._log.warning(f'no signal {signal}')
				setattr(self, f'_{signal}', None)

		if not self._clk:
			raise Exception('no clock signal!')
		else:
			self._clock = Clock(dut.clk, 10, 'ns')
			cocotb.start_soon(self._clock.start())

		if self._read and not self._readdata:
			raise Exception('read signal but no readdata!')
		else:
			self._read.value = 0

		if self._write and not self._writedata:
			raise Exception('write signal but no writedata!')
		else:
			self._write.value = 0

	@coroutine
	async def reset(self):
		if self._reset:
			self._dut._log.info('performing active high reset')
			self._reset.value = 1
			await RisingEdge(self._clk)
			self._reset.value = 0
			self._dut._log.info('done reset')
		elif self._reset_n:
			self._dut._log.info('performing active low reset')
			self._reset_n.value = 0
			await RisingEdge(self._clk)
			self._reset_n.value = 1
			self._dut._log.info('done reset')
	def read(self, addr):
		pass

	def write(self, addr):
		pass
	

class avalon_agent(avalon_interface):
#			self._signal[signal] = getattr(dut, signal) \
#						if hasattr(dut, signal) \
#						else None

	def __init__(self, dut):
		avalon_interface.__init__(self, dut)
		dut._log.info('created avalon agent')

	@coroutine
	async def read(self, addr):
		self._address.value = addr
		self._read.value = 1
		await RisingEdge(self._clk)
		self._read.value = 0
		await RisingEdge(self._clk)
		data = self._readdata.value.integer
		return data

	@coroutine
	async def write(self, addr, value):
		self._address.value = addr
		self._write.value = 1
		self._writedata.value = value
		await RisingEdge(self._clk)
		self._write.value = 0

class digit(object):
	def __init__(self, screen, offset, scale = 1, connector = connector_type.common_anode):
		self.__screen = screen
		self.__offset = offset
		self.__scale = scale
		self.__connector = connector

	def draw(self, digits):
		for c, d in enumerate(digits):
			poly = self.__get_poly(c)
			poly = [self.__transform(p) for p in poly]
			color = (255, 0, 0) \
						if (d == 0 \
								and self.__connector \
									== connector_type.common_anode) \
							or (d == 1 \
								and self.__connector \
									== connector_type.common_cathode) \
					else (64, 0, 0)
			pygame.draw.polygon(self.__screen, color, poly)

	def __get_poly(self, segment):
		return {
			0: [(10, 10), (12, 8), (18, 8),
				(20, 10), (18, 12), (12, 12)],
			1: [(22, 12), (24, 14), (24, 22),
				(22, 24), (20, 22), (20, 14)],
			2: [(22, 28), (24, 30), (24, 38),
				(22, 40), (20, 38), (20, 30)],
			3: [(10, 42), (12, 40), (18, 40),
				(20, 42), (18, 44), (12, 44)],
			4: [(8, 28), (10, 30), (10, 38),
				(8, 40), (6, 38), (6, 30)],
			5: [(8, 12), (10, 14), (10, 22),
				(8, 24), (6, 22), (6, 14)],
			6: [(10, 26), (12, 24), (18, 24),
				(20, 26), (18, 28), (12, 28)]
			}.get(segment, [(0, 0), (1, 1), (0, 1)])

	def __transform(self, point):
		return tuple(self.__scale * (point[i] + self.__offset[i])
			for i in range(2))

class direct(enum.Enum):
	up = 0
	down = 1
	hold = 2

@cocotb.test()
def testbench(dut):
	get_bits = lambda val, bits: ((val >> bits) & 1) if isinstance(bits, int) \
					else ((val >> bits[1]) & int('1' * (bits[0] - bits[1] + 1), 2))

	pygame.init()
	screen = pygame.display.set_mode((640, 240))
	sseg = [digit(screen, (26*i, 0), 4) for i in range(6)[::-1]]
	count_dir = direct.hold
	prev_count_dir = direct.hold
	count = 0
	clock = pygame.time.Clock()

	avalon_mm = avalon_agent(dut)
	yield avalon_mm.reset()

	magic = yield avalon_mm.read(3)
	dut._log.info(f'magic number: {magic:8x}')
	dut._log.info(f'              {"".join(chr(get_bits(magic, (8*i+7,8*i))) for i in range(4))[::-1]}')
	features = yield avalon_mm.read(2)
	dut._log.info(f'features:     {features:8x}')
	dut._log.info(f'    impl:     {get_bits(features, (31, 24)):2x}')
	dut._log.info(f'     rev:     {get_bits(features, (23, 16)):2x}')
	dut._log.info(f' lampcfg:     common {"anode" if get_bits(features, 3) else "cathode"}')
	dut._log.info(f'   blank:     {"yes" if get_bits(features, 2) else "no"}')
	dut._log.info(f'     neg:     {"yes" if get_bits(features, 1) else "no"}')
	dut._log.info(f'     dec:     {"yes" if get_bits(features, 0) else "no"}')

	yield Timer(10)

	while True:
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				return
			elif event.type == pygame.KEYUP:
				match event.dict['unicode']:
					case 'q' | 'Q':
						return
					case 'o' | 'O':
						dut._log.info('toggle lamps')
						control_reg = yield avalon_mm.read(1)
						control_reg ^= 0b0001
						yield avalon_mm.write(1, control_reg)
						dut._log.info(f'lamps toggled ({yield avalon_mm.read(1):0{8}x})')
					case 'd' | 'D':
						dut._log.info('toggle decimal')
						control_reg = yield avalon_mm.read(1)
						control_reg ^= 0b0010
						yield avalon_mm.write(1, control_reg)
						dut._log.info(f'decimal toggled ({yield avalon_mm.read(1):0{8}x})')
					case 'b' | 'B':
						dut._log.info('toggle blanking')
						control_reg = yield avalon_mm.read(1)
						control_reg ^= 0b0100
						yield avalon_mm.write(1, control_reg)
						dut._log.info(f'blanking toggled ({yield avalon_mm.read(1):0{8}x})')
					case 's' | 'S':
						dut._log.info('toggle signed')
						control_reg = yield avalon_mm.read(1)
						control_reg ^= 0b1000
						yield avalon_mm.write(1, control_reg)
						dut._log.info(f'signed toggled ({yield avalon_mm.read(1):0{8}x})')
					case 'r' | 'R':
						dut._log.info('reset count')
						count = 0
					case 't' | 'T':
						dut._log.info('toggle count direction')
						count_dir = direct.down if count_dir == direct.up \
								else direct.up
					case 'p' | 'P':
						dut._log.info('pause count')
						if count_dir != direct.hold:
							prev_count_dir = count_dir
							count_dir = direct.hold
						elif prev_count_dir == direct.hold:
							count_dir = direct.up
						else:
							count_dir = prev_count_dir
					case 'v' | 'V':
						dut._log.info(f'count ={count}\n'
							  f'number={yield avalon_mm.read(0):0{8}x}\n'
							  f'ctrl  ={yield avalon_mm.read(1):0{8}x}')
					case other:
						pass

		data = dut.digits.value
		for pos, display in enumerate(sseg):
			fragment = str(data)[::-1][7*pos:7*pos+7]
			display.draw([int(x) for x in str(fragment)])
		pygame.display.flip()
		if count_dir == direct.up:
			count = (count + 1) if count < 2**16 else -2**16
			yield avalon_mm.write(0, count)
		elif count_dir == direct.down:
			count = (count - 1) if count >= -2**16 else (2**16 - 1)
			yield avalon_mm.write(0, count)
		clock.tick(5)
	
