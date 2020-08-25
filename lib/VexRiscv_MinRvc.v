// Generator : SpinalHDL v1.3.5    git head : f0505d24810c8661a24530409359554b7cfa271a
// Date      : 24/08/2020, 21:45:35
// Component : VexRiscv


`define AluBitwiseCtrlEnum_defaultEncoding_type [1:0]
`define AluBitwiseCtrlEnum_defaultEncoding_XOR_1 2'b00
`define AluBitwiseCtrlEnum_defaultEncoding_OR_1 2'b01
`define AluBitwiseCtrlEnum_defaultEncoding_AND_1 2'b10

`define Src1CtrlEnum_defaultEncoding_type [1:0]
`define Src1CtrlEnum_defaultEncoding_RS 2'b00
`define Src1CtrlEnum_defaultEncoding_IMU 2'b01
`define Src1CtrlEnum_defaultEncoding_PC_INCREMENT 2'b10
`define Src1CtrlEnum_defaultEncoding_URS1 2'b11

`define Src2CtrlEnum_defaultEncoding_type [1:0]
`define Src2CtrlEnum_defaultEncoding_RS 2'b00
`define Src2CtrlEnum_defaultEncoding_IMI 2'b01
`define Src2CtrlEnum_defaultEncoding_IMS 2'b10
`define Src2CtrlEnum_defaultEncoding_PC 2'b11

`define EnvCtrlEnum_defaultEncoding_type [0:0]
`define EnvCtrlEnum_defaultEncoding_NONE 1'b0
`define EnvCtrlEnum_defaultEncoding_XRET 1'b1

`define AluCtrlEnum_defaultEncoding_type [1:0]
`define AluCtrlEnum_defaultEncoding_ADD_SUB 2'b00
`define AluCtrlEnum_defaultEncoding_SLT_SLTU 2'b01
`define AluCtrlEnum_defaultEncoding_BITWISE 2'b10

`define ShiftCtrlEnum_defaultEncoding_type [1:0]
`define ShiftCtrlEnum_defaultEncoding_DISABLE_1 2'b00
`define ShiftCtrlEnum_defaultEncoding_SLL_1 2'b01
`define ShiftCtrlEnum_defaultEncoding_SRL_1 2'b10
`define ShiftCtrlEnum_defaultEncoding_SRA_1 2'b11

`define BranchCtrlEnum_defaultEncoding_type [1:0]
`define BranchCtrlEnum_defaultEncoding_INC 2'b00
`define BranchCtrlEnum_defaultEncoding_B 2'b01
`define BranchCtrlEnum_defaultEncoding_JAL 2'b10
`define BranchCtrlEnum_defaultEncoding_JALR 2'b11

module StreamFifoLowLatency (
      input   io_push_valid,
      output  io_push_ready,
      input   io_push_payload_error,
      input  [31:0] io_push_payload_inst,
      output reg  io_pop_valid,
      input   io_pop_ready,
      output reg  io_pop_payload_error,
      output reg [31:0] io_pop_payload_inst,
      input   io_flush,
      output [0:0] io_occupancy,
      input   clk,
      input   reset);
  wire  _zz_5_;
  wire [0:0] _zz_6_;
  reg  _zz_1_;
  reg  pushPtr_willIncrement;
  reg  pushPtr_willClear;
  wire  pushPtr_willOverflowIfInc;
  wire  pushPtr_willOverflow;
  reg  popPtr_willIncrement;
  reg  popPtr_willClear;
  wire  popPtr_willOverflowIfInc;
  wire  popPtr_willOverflow;
  wire  ptrMatch;
  reg  risingOccupancy;
  wire  empty;
  wire  full;
  wire  pushing;
  wire  popping;
  wire [32:0] _zz_2_;
  wire [32:0] _zz_3_;
  reg [32:0] _zz_4_;
  assign _zz_5_ = (! empty);
  assign _zz_6_ = _zz_2_[0 : 0];
  always @ (*) begin
    _zz_1_ = 1'b0;
    if(pushing)begin
      _zz_1_ = 1'b1;
    end
  end

  always @ (*) begin
    pushPtr_willIncrement = 1'b0;
    if(pushing)begin
      pushPtr_willIncrement = 1'b1;
    end
  end

  always @ (*) begin
    pushPtr_willClear = 1'b0;
    if(io_flush)begin
      pushPtr_willClear = 1'b1;
    end
  end

  assign pushPtr_willOverflowIfInc = 1'b1;
  assign pushPtr_willOverflow = (pushPtr_willOverflowIfInc && pushPtr_willIncrement);
  always @ (*) begin
    popPtr_willIncrement = 1'b0;
    if(popping)begin
      popPtr_willIncrement = 1'b1;
    end
  end

  always @ (*) begin
    popPtr_willClear = 1'b0;
    if(io_flush)begin
      popPtr_willClear = 1'b1;
    end
  end

  assign popPtr_willOverflowIfInc = 1'b1;
  assign popPtr_willOverflow = (popPtr_willOverflowIfInc && popPtr_willIncrement);
  assign ptrMatch = 1'b1;
  assign empty = (ptrMatch && (! risingOccupancy));
  assign full = (ptrMatch && risingOccupancy);
  assign pushing = (io_push_valid && io_push_ready);
  assign popping = (io_pop_valid && io_pop_ready);
  assign io_push_ready = (! full);
  always @ (*) begin
    if(_zz_5_)begin
      io_pop_valid = 1'b1;
    end else begin
      io_pop_valid = io_push_valid;
    end
  end

  assign _zz_2_ = _zz_3_;
  always @ (*) begin
    if(_zz_5_)begin
      io_pop_payload_error = _zz_6_[0];
    end else begin
      io_pop_payload_error = io_push_payload_error;
    end
  end

  always @ (*) begin
    if(_zz_5_)begin
      io_pop_payload_inst = _zz_2_[32 : 1];
    end else begin
      io_pop_payload_inst = io_push_payload_inst;
    end
  end

  assign io_occupancy = (risingOccupancy && ptrMatch);
  assign _zz_3_ = _zz_4_;
  always @ (posedge clk) begin
    if(reset) begin
      risingOccupancy <= 1'b0;
    end else begin
      if((pushing != popping))begin
        risingOccupancy <= pushing;
      end
      if(io_flush)begin
        risingOccupancy <= 1'b0;
      end
    end
  end

  always @ (posedge clk) begin
    if(_zz_1_)begin
      _zz_4_ <= {io_push_payload_inst,io_push_payload_error};
    end
  end

endmodule

module VexRiscv (
      input  [31:0] externalResetVector,
      input   timerInterrupt,
      input   softwareInterrupt,
      input  [31:0] externalInterruptArray,
      output  iBusWishbone_CYC,
      output  iBusWishbone_STB,
      input   iBusWishbone_ACK,
      output  iBusWishbone_WE,
      output [29:0] iBusWishbone_ADR,
      input  [31:0] iBusWishbone_DAT_MISO,
      output [31:0] iBusWishbone_DAT_MOSI,
      output [3:0] iBusWishbone_SEL,
      input   iBusWishbone_ERR,
      output [1:0] iBusWishbone_BTE,
      output [2:0] iBusWishbone_CTI,
      output  dBusWishbone_CYC,
      output  dBusWishbone_STB,
      input   dBusWishbone_ACK,
      output  dBusWishbone_WE,
      output [29:0] dBusWishbone_ADR,
      input  [31:0] dBusWishbone_DAT_MISO,
      output [31:0] dBusWishbone_DAT_MOSI,
      output reg [3:0] dBusWishbone_SEL,
      input   dBusWishbone_ERR,
      output [1:0] dBusWishbone_BTE,
      output [2:0] dBusWishbone_CTI,
      input   clk,
      input   reset);
  wire  _zz_189_;
  reg [31:0] _zz_190_;
  reg [31:0] _zz_191_;
  reg [31:0] _zz_192_;
  wire  IBusSimplePlugin_rspJoin_rspBuffer_c_io_push_ready;
  wire  IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_valid;
  wire  IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_error;
  wire [31:0] IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_inst;
  wire [0:0] IBusSimplePlugin_rspJoin_rspBuffer_c_io_occupancy;
  wire  _zz_193_;
  wire  _zz_194_;
  wire  _zz_195_;
  wire  _zz_196_;
  wire  _zz_197_;
  wire  _zz_198_;
  wire [1:0] _zz_199_;
  wire  _zz_200_;
  wire  _zz_201_;
  wire  _zz_202_;
  wire  _zz_203_;
  wire  _zz_204_;
  wire  _zz_205_;
  wire  _zz_206_;
  wire  _zz_207_;
  wire  _zz_208_;
  wire  _zz_209_;
  wire  _zz_210_;
  wire  _zz_211_;
  wire  _zz_212_;
  wire  _zz_213_;
  wire  _zz_214_;
  wire  _zz_215_;
  wire  _zz_216_;
  wire [4:0] _zz_217_;
  wire [1:0] _zz_218_;
  wire [1:0] _zz_219_;
  wire [1:0] _zz_220_;
  wire  _zz_221_;
  wire [3:0] _zz_222_;
  wire [2:0] _zz_223_;
  wire [31:0] _zz_224_;
  wire [2:0] _zz_225_;
  wire [31:0] _zz_226_;
  wire [31:0] _zz_227_;
  wire [11:0] _zz_228_;
  wire [11:0] _zz_229_;
  wire [2:0] _zz_230_;
  wire [31:0] _zz_231_;
  wire [2:0] _zz_232_;
  wire [0:0] _zz_233_;
  wire [2:0] _zz_234_;
  wire [0:0] _zz_235_;
  wire [2:0] _zz_236_;
  wire [0:0] _zz_237_;
  wire [2:0] _zz_238_;
  wire [0:0] _zz_239_;
  wire [2:0] _zz_240_;
  wire [2:0] _zz_241_;
  wire [0:0] _zz_242_;
  wire [0:0] _zz_243_;
  wire [0:0] _zz_244_;
  wire [0:0] _zz_245_;
  wire [0:0] _zz_246_;
  wire [0:0] _zz_247_;
  wire [0:0] _zz_248_;
  wire [0:0] _zz_249_;
  wire [0:0] _zz_250_;
  wire [0:0] _zz_251_;
  wire [0:0] _zz_252_;
  wire [0:0] _zz_253_;
  wire [2:0] _zz_254_;
  wire [4:0] _zz_255_;
  wire [11:0] _zz_256_;
  wire [11:0] _zz_257_;
  wire [31:0] _zz_258_;
  wire [31:0] _zz_259_;
  wire [31:0] _zz_260_;
  wire [31:0] _zz_261_;
  wire [31:0] _zz_262_;
  wire [31:0] _zz_263_;
  wire [31:0] _zz_264_;
  wire [31:0] _zz_265_;
  wire [32:0] _zz_266_;
  wire [19:0] _zz_267_;
  wire [11:0] _zz_268_;
  wire [11:0] _zz_269_;
  wire [1:0] _zz_270_;
  wire [1:0] _zz_271_;
  wire [0:0] _zz_272_;
  wire [0:0] _zz_273_;
  wire [0:0] _zz_274_;
  wire [0:0] _zz_275_;
  wire [0:0] _zz_276_;
  wire [0:0] _zz_277_;
  wire [6:0] _zz_278_;
  wire  _zz_279_;
  wire  _zz_280_;
  wire [1:0] _zz_281_;
  wire  _zz_282_;
  wire  _zz_283_;
  wire [6:0] _zz_284_;
  wire [4:0] _zz_285_;
  wire  _zz_286_;
  wire [4:0] _zz_287_;
  wire [31:0] _zz_288_;
  wire  _zz_289_;
  wire  _zz_290_;
  wire  _zz_291_;
  wire [1:0] _zz_292_;
  wire [1:0] _zz_293_;
  wire  _zz_294_;
  wire [0:0] _zz_295_;
  wire [18:0] _zz_296_;
  wire [31:0] _zz_297_;
  wire [31:0] _zz_298_;
  wire [31:0] _zz_299_;
  wire [31:0] _zz_300_;
  wire  _zz_301_;
  wire  _zz_302_;
  wire  _zz_303_;
  wire [0:0] _zz_304_;
  wire [0:0] _zz_305_;
  wire  _zz_306_;
  wire [0:0] _zz_307_;
  wire [15:0] _zz_308_;
  wire [31:0] _zz_309_;
  wire [31:0] _zz_310_;
  wire [31:0] _zz_311_;
  wire  _zz_312_;
  wire [1:0] _zz_313_;
  wire [1:0] _zz_314_;
  wire  _zz_315_;
  wire [0:0] _zz_316_;
  wire [12:0] _zz_317_;
  wire [31:0] _zz_318_;
  wire [31:0] _zz_319_;
  wire [31:0] _zz_320_;
  wire [31:0] _zz_321_;
  wire [31:0] _zz_322_;
  wire [31:0] _zz_323_;
  wire [0:0] _zz_324_;
  wire [0:0] _zz_325_;
  wire [1:0] _zz_326_;
  wire [1:0] _zz_327_;
  wire  _zz_328_;
  wire [0:0] _zz_329_;
  wire [9:0] _zz_330_;
  wire [31:0] _zz_331_;
  wire [31:0] _zz_332_;
  wire [31:0] _zz_333_;
  wire [31:0] _zz_334_;
  wire [31:0] _zz_335_;
  wire [2:0] _zz_336_;
  wire [2:0] _zz_337_;
  wire  _zz_338_;
  wire [0:0] _zz_339_;
  wire [6:0] _zz_340_;
  wire [31:0] _zz_341_;
  wire [31:0] _zz_342_;
  wire  _zz_343_;
  wire  _zz_344_;
  wire  _zz_345_;
  wire  _zz_346_;
  wire [0:0] _zz_347_;
  wire [0:0] _zz_348_;
  wire [2:0] _zz_349_;
  wire [2:0] _zz_350_;
  wire  _zz_351_;
  wire [0:0] _zz_352_;
  wire [3:0] _zz_353_;
  wire [31:0] _zz_354_;
  wire [31:0] _zz_355_;
  wire [31:0] _zz_356_;
  wire [31:0] _zz_357_;
  wire [31:0] _zz_358_;
  wire [31:0] _zz_359_;
  wire [31:0] _zz_360_;
  wire [31:0] _zz_361_;
  wire  _zz_362_;
  wire [0:0] _zz_363_;
  wire [0:0] _zz_364_;
  wire [0:0] _zz_365_;
  wire [2:0] _zz_366_;
  wire [5:0] _zz_367_;
  wire [5:0] _zz_368_;
  wire  _zz_369_;
  wire [0:0] _zz_370_;
  wire [1:0] _zz_371_;
  wire [31:0] _zz_372_;
  wire [31:0] _zz_373_;
  wire [31:0] _zz_374_;
  wire [31:0] _zz_375_;
  wire [31:0] _zz_376_;
  wire [31:0] _zz_377_;
  wire [31:0] _zz_378_;
  wire  _zz_379_;
  wire [0:0] _zz_380_;
  wire [0:0] _zz_381_;
  wire [0:0] _zz_382_;
  wire [3:0] _zz_383_;
  wire [0:0] _zz_384_;
  wire [0:0] _zz_385_;
  wire [0:0] _zz_386_;
  wire [0:0] _zz_387_;
  wire  _zz_388_;
  wire  _zz_389_;
  wire [31:0] _zz_390_;
  wire [31:0] _zz_391_;
  wire [31:0] _zz_392_;
  wire [31:0] _zz_393_;
  wire [31:0] _zz_394_;
  wire [31:0] _zz_395_;
  wire [31:0] _zz_396_;
  wire  _zz_397_;
  wire [0:0] _zz_398_;
  wire [1:0] _zz_399_;
  wire [31:0] _zz_400_;
  wire [31:0] _zz_401_;
  wire [31:0] _zz_402_;
  wire [31:0] _zz_403_;
  wire [0:0] _zz_404_;
  wire [0:0] _zz_405_;
  wire [0:0] _zz_406_;
  wire [0:0] _zz_407_;
  wire [31:0] _zz_408_;
  wire [31:0] _zz_409_;
  wire [31:0] _zz_410_;
  wire  _zz_411_;
  wire [0:0] _zz_412_;
  wire [10:0] _zz_413_;
  wire [31:0] _zz_414_;
  wire [31:0] _zz_415_;
  wire [31:0] _zz_416_;
  wire  _zz_417_;
  wire [0:0] _zz_418_;
  wire [4:0] _zz_419_;
  wire [31:0] _zz_420_;
  wire [31:0] _zz_421_;
  wire [31:0] _zz_422_;
  wire [31:0] _zz_423_;
  wire [31:0] _zz_424_;
  wire [31:0] decode_RS2;
  wire [1:0] memory_MEMORY_ADDRESS_LOW;
  wire [1:0] execute_MEMORY_ADDRESS_LOW;
  wire [31:0] writeBack_REGFILE_WRITE_DATA;
  wire [31:0] execute_REGFILE_WRITE_DATA;
  wire [31:0] memory_MEMORY_READ_DATA;
  wire [31:0] execute_BRANCH_CALC;
  wire `AluBitwiseCtrlEnum_defaultEncoding_type decode_ALU_BITWISE_CTRL;
  wire `AluBitwiseCtrlEnum_defaultEncoding_type _zz_1_;
  wire `AluBitwiseCtrlEnum_defaultEncoding_type _zz_2_;
  wire `AluBitwiseCtrlEnum_defaultEncoding_type _zz_3_;
  wire `Src1CtrlEnum_defaultEncoding_type decode_SRC1_CTRL;
  wire `Src1CtrlEnum_defaultEncoding_type _zz_4_;
  wire `Src1CtrlEnum_defaultEncoding_type _zz_5_;
  wire `Src1CtrlEnum_defaultEncoding_type _zz_6_;
  wire [31:0] writeBack_FORMAL_PC_NEXT;
  wire [31:0] memory_FORMAL_PC_NEXT;
  wire [31:0] execute_FORMAL_PC_NEXT;
  wire [31:0] decode_FORMAL_PC_NEXT;
  wire `Src2CtrlEnum_defaultEncoding_type decode_SRC2_CTRL;
  wire `Src2CtrlEnum_defaultEncoding_type _zz_7_;
  wire `Src2CtrlEnum_defaultEncoding_type _zz_8_;
  wire `Src2CtrlEnum_defaultEncoding_type _zz_9_;
  wire [31:0] decode_RS1;
  wire  decode_SRC2_FORCE_ZERO;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_10_;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_11_;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_12_;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_13_;
  wire `EnvCtrlEnum_defaultEncoding_type decode_ENV_CTRL;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_14_;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_15_;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_16_;
  wire  decode_IS_CSR;
  wire `AluCtrlEnum_defaultEncoding_type decode_ALU_CTRL;
  wire `AluCtrlEnum_defaultEncoding_type _zz_17_;
  wire `AluCtrlEnum_defaultEncoding_type _zz_18_;
  wire `AluCtrlEnum_defaultEncoding_type _zz_19_;
  wire  execute_BRANCH_DO;
  wire `ShiftCtrlEnum_defaultEncoding_type decode_SHIFT_CTRL;
  wire `ShiftCtrlEnum_defaultEncoding_type _zz_20_;
  wire `ShiftCtrlEnum_defaultEncoding_type _zz_21_;
  wire `ShiftCtrlEnum_defaultEncoding_type _zz_22_;
  wire  decode_SRC_LESS_UNSIGNED;
  wire  execute_BYPASSABLE_MEMORY_STAGE;
  wire  decode_BYPASSABLE_MEMORY_STAGE;
  wire  decode_BYPASSABLE_EXECUTE_STAGE;
  wire  decode_CSR_READ_OPCODE;
  wire  decode_MEMORY_STORE;
  wire `BranchCtrlEnum_defaultEncoding_type decode_BRANCH_CTRL;
  wire `BranchCtrlEnum_defaultEncoding_type _zz_23_;
  wire `BranchCtrlEnum_defaultEncoding_type _zz_24_;
  wire `BranchCtrlEnum_defaultEncoding_type _zz_25_;
  wire  decode_CSR_WRITE_OPCODE;
  wire  execute_CSR_READ_OPCODE;
  wire  execute_CSR_WRITE_OPCODE;
  wire  execute_IS_CSR;
  wire `EnvCtrlEnum_defaultEncoding_type memory_ENV_CTRL;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_26_;
  wire `EnvCtrlEnum_defaultEncoding_type execute_ENV_CTRL;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_27_;
  wire  _zz_28_;
  wire  _zz_29_;
  wire `EnvCtrlEnum_defaultEncoding_type writeBack_ENV_CTRL;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_30_;
  wire [31:0] memory_BRANCH_CALC;
  wire  memory_BRANCH_DO;
  wire [31:0] _zz_31_;
  wire [31:0] execute_PC;
  wire [31:0] execute_RS1;
  wire `BranchCtrlEnum_defaultEncoding_type execute_BRANCH_CTRL;
  wire `BranchCtrlEnum_defaultEncoding_type _zz_32_;
  wire  _zz_33_;
  wire  decode_RS2_USE;
  wire  decode_RS1_USE;
  wire  execute_REGFILE_WRITE_VALID;
  wire  execute_BYPASSABLE_EXECUTE_STAGE;
  wire  memory_REGFILE_WRITE_VALID;
  wire [31:0] memory_INSTRUCTION;
  wire  memory_BYPASSABLE_MEMORY_STAGE;
  wire  writeBack_REGFILE_WRITE_VALID;
  reg [31:0] _zz_34_;
  wire `ShiftCtrlEnum_defaultEncoding_type execute_SHIFT_CTRL;
  wire `ShiftCtrlEnum_defaultEncoding_type _zz_35_;
  wire  _zz_36_;
  wire [31:0] _zz_37_;
  wire [31:0] _zz_38_;
  wire  execute_SRC_LESS_UNSIGNED;
  wire  execute_SRC2_FORCE_ZERO;
  wire  execute_SRC_USE_SUB_LESS;
  wire [31:0] _zz_39_;
  wire `Src2CtrlEnum_defaultEncoding_type execute_SRC2_CTRL;
  wire `Src2CtrlEnum_defaultEncoding_type _zz_40_;
  wire [31:0] _zz_41_;
  wire  execute_IS_RVC;
  wire `Src1CtrlEnum_defaultEncoding_type execute_SRC1_CTRL;
  wire `Src1CtrlEnum_defaultEncoding_type _zz_42_;
  wire [31:0] _zz_43_;
  wire  decode_SRC_USE_SUB_LESS;
  wire  decode_SRC_ADD_ZERO;
  wire  _zz_44_;
  wire [31:0] execute_SRC_ADD_SUB;
  wire  execute_SRC_LESS;
  wire `AluCtrlEnum_defaultEncoding_type execute_ALU_CTRL;
  wire `AluCtrlEnum_defaultEncoding_type _zz_45_;
  wire [31:0] _zz_46_;
  wire [31:0] execute_SRC2;
  wire [31:0] execute_SRC1;
  wire `AluBitwiseCtrlEnum_defaultEncoding_type execute_ALU_BITWISE_CTRL;
  wire `AluBitwiseCtrlEnum_defaultEncoding_type _zz_47_;
  wire [31:0] _zz_48_;
  wire  _zz_49_;
  reg  _zz_50_;
  wire [31:0] _zz_51_;
  wire [31:0] _zz_52_;
  wire [31:0] decode_INSTRUCTION_ANTICIPATED;
  reg  decode_REGFILE_WRITE_VALID;
  wire  decode_LEGAL_INSTRUCTION;
  wire  decode_INSTRUCTION_READY;
  wire  _zz_53_;
  wire  _zz_54_;
  wire `ShiftCtrlEnum_defaultEncoding_type _zz_55_;
  wire  _zz_56_;
  wire `AluBitwiseCtrlEnum_defaultEncoding_type _zz_57_;
  wire  _zz_58_;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_59_;
  wire `AluCtrlEnum_defaultEncoding_type _zz_60_;
  wire `Src2CtrlEnum_defaultEncoding_type _zz_61_;
  wire  _zz_62_;
  wire  _zz_63_;
  wire  _zz_64_;
  wire  _zz_65_;
  wire  _zz_66_;
  wire  _zz_67_;
  wire  _zz_68_;
  wire `BranchCtrlEnum_defaultEncoding_type _zz_69_;
  wire `Src1CtrlEnum_defaultEncoding_type _zz_70_;
  wire  _zz_71_;
  wire  writeBack_MEMORY_STORE;
  reg [31:0] _zz_72_;
  wire  writeBack_MEMORY_ENABLE;
  wire [1:0] writeBack_MEMORY_ADDRESS_LOW;
  wire [31:0] writeBack_MEMORY_READ_DATA;
  wire  memory_MMU_FAULT;
  wire [31:0] memory_MMU_RSP_physicalAddress;
  wire  memory_MMU_RSP_isIoAccess;
  wire  memory_MMU_RSP_allowRead;
  wire  memory_MMU_RSP_allowWrite;
  wire  memory_MMU_RSP_allowExecute;
  wire  memory_MMU_RSP_exception;
  wire  memory_MMU_RSP_refilling;
  wire [31:0] memory_PC;
  wire  memory_ALIGNEMENT_FAULT;
  wire [31:0] memory_REGFILE_WRITE_DATA;
  wire  memory_MEMORY_STORE;
  wire  memory_MEMORY_ENABLE;
  wire [31:0] _zz_73_;
  wire [31:0] _zz_74_;
  wire  _zz_75_;
  wire  _zz_76_;
  wire  _zz_77_;
  wire  _zz_78_;
  wire  _zz_79_;
  wire  _zz_80_;
  wire  execute_MMU_FAULT;
  wire [31:0] execute_MMU_RSP_physicalAddress;
  wire  execute_MMU_RSP_isIoAccess;
  wire  execute_MMU_RSP_allowRead;
  wire  execute_MMU_RSP_allowWrite;
  wire  execute_MMU_RSP_allowExecute;
  wire  execute_MMU_RSP_exception;
  wire  execute_MMU_RSP_refilling;
  wire  _zz_81_;
  wire [31:0] execute_SRC_ADD;
  wire [1:0] _zz_82_;
  wire [31:0] execute_RS2;
  wire [31:0] execute_INSTRUCTION;
  wire  execute_MEMORY_STORE;
  wire  execute_MEMORY_ENABLE;
  wire  execute_ALIGNEMENT_FAULT;
  wire  _zz_83_;
  wire  decode_MEMORY_ENABLE;
  reg [31:0] _zz_84_;
  reg [31:0] _zz_85_;
  wire [31:0] decode_PC;
  wire [31:0] _zz_86_;
  wire  _zz_87_;
  wire [31:0] _zz_88_;
  wire [31:0] _zz_89_;
  wire [31:0] decode_INSTRUCTION;
  wire [31:0] _zz_90_;
  wire  decode_IS_RVC;
  wire [31:0] writeBack_PC;
  wire [31:0] writeBack_INSTRUCTION;
  reg  decode_arbitration_haltItself;
  reg  decode_arbitration_haltByOther;
  reg  decode_arbitration_removeIt;
  reg  decode_arbitration_flushAll;
  wire  decode_arbitration_isValid;
  wire  decode_arbitration_isStuck;
  wire  decode_arbitration_isStuckByOthers;
  wire  decode_arbitration_isFlushed;
  wire  decode_arbitration_isMoving;
  wire  decode_arbitration_isFiring;
  reg  execute_arbitration_haltItself;
  wire  execute_arbitration_haltByOther;
  reg  execute_arbitration_removeIt;
  reg  execute_arbitration_flushAll;
  reg  execute_arbitration_isValid;
  wire  execute_arbitration_isStuck;
  wire  execute_arbitration_isStuckByOthers;
  wire  execute_arbitration_isFlushed;
  wire  execute_arbitration_isMoving;
  wire  execute_arbitration_isFiring;
  reg  memory_arbitration_haltItself;
  wire  memory_arbitration_haltByOther;
  reg  memory_arbitration_removeIt;
  reg  memory_arbitration_flushAll;
  reg  memory_arbitration_isValid;
  wire  memory_arbitration_isStuck;
  wire  memory_arbitration_isStuckByOthers;
  wire  memory_arbitration_isFlushed;
  wire  memory_arbitration_isMoving;
  wire  memory_arbitration_isFiring;
  wire  writeBack_arbitration_haltItself;
  wire  writeBack_arbitration_haltByOther;
  reg  writeBack_arbitration_removeIt;
  wire  writeBack_arbitration_flushAll;
  reg  writeBack_arbitration_isValid;
  wire  writeBack_arbitration_isStuck;
  wire  writeBack_arbitration_isStuckByOthers;
  wire  writeBack_arbitration_isFlushed;
  wire  writeBack_arbitration_isMoving;
  wire  writeBack_arbitration_isFiring;
  wire [31:0] lastStageInstruction /* verilator public */ ;
  wire [31:0] lastStagePc /* verilator public */ ;
  wire  lastStageIsValid /* verilator public */ ;
  wire  lastStageIsFiring /* verilator public */ ;
  reg  IBusSimplePlugin_fetcherHalt;
  wire  IBusSimplePlugin_fetcherflushIt;
  reg  IBusSimplePlugin_incomingInstruction;
  wire  IBusSimplePlugin_pcValids_0;
  wire  IBusSimplePlugin_pcValids_1;
  wire  IBusSimplePlugin_pcValids_2;
  wire  IBusSimplePlugin_pcValids_3;
  wire  iBus_cmd_valid;
  wire  iBus_cmd_ready;
  wire [31:0] iBus_cmd_payload_pc;
  wire  iBus_rsp_valid;
  wire  iBus_rsp_payload_error;
  wire [31:0] iBus_rsp_payload_inst;
  wire  IBusSimplePlugin_decodeExceptionPort_valid;
  reg [3:0] IBusSimplePlugin_decodeExceptionPort_payload_code;
  wire [31:0] IBusSimplePlugin_decodeExceptionPort_payload_badAddr;
  wire  IBusSimplePlugin_mmuBus_cmd_isValid;
  wire [31:0] IBusSimplePlugin_mmuBus_cmd_virtualAddress;
  wire  IBusSimplePlugin_mmuBus_cmd_bypassTranslation;
  wire [31:0] IBusSimplePlugin_mmuBus_rsp_physicalAddress;
  wire  IBusSimplePlugin_mmuBus_rsp_isIoAccess;
  wire  IBusSimplePlugin_mmuBus_rsp_allowRead;
  wire  IBusSimplePlugin_mmuBus_rsp_allowWrite;
  wire  IBusSimplePlugin_mmuBus_rsp_allowExecute;
  wire  IBusSimplePlugin_mmuBus_rsp_exception;
  wire  IBusSimplePlugin_mmuBus_rsp_refilling;
  wire  IBusSimplePlugin_mmuBus_end;
  wire  IBusSimplePlugin_mmuBus_busy;
  wire  IBusSimplePlugin_redoBranch_valid;
  wire [31:0] IBusSimplePlugin_redoBranch_payload;
  reg  DBusSimplePlugin_memoryExceptionPort_valid;
  reg [3:0] DBusSimplePlugin_memoryExceptionPort_payload_code;
  wire [31:0] DBusSimplePlugin_memoryExceptionPort_payload_badAddr;
  wire  DBusSimplePlugin_mmuBus_cmd_isValid;
  wire [31:0] DBusSimplePlugin_mmuBus_cmd_virtualAddress;
  wire  DBusSimplePlugin_mmuBus_cmd_bypassTranslation;
  wire [31:0] DBusSimplePlugin_mmuBus_rsp_physicalAddress;
  wire  DBusSimplePlugin_mmuBus_rsp_isIoAccess;
  wire  DBusSimplePlugin_mmuBus_rsp_allowRead;
  wire  DBusSimplePlugin_mmuBus_rsp_allowWrite;
  wire  DBusSimplePlugin_mmuBus_rsp_allowExecute;
  wire  DBusSimplePlugin_mmuBus_rsp_exception;
  wire  DBusSimplePlugin_mmuBus_rsp_refilling;
  wire  DBusSimplePlugin_mmuBus_end;
  wire  DBusSimplePlugin_mmuBus_busy;
  reg  DBusSimplePlugin_redoBranch_valid;
  wire [31:0] DBusSimplePlugin_redoBranch_payload;
  wire  decodeExceptionPort_valid;
  wire [3:0] decodeExceptionPort_payload_code;
  wire [31:0] decodeExceptionPort_payload_badAddr;
  wire  BranchPlugin_jumpInterface_valid;
  wire [31:0] BranchPlugin_jumpInterface_payload;
  reg  CsrPlugin_jumpInterface_valid;
  reg [31:0] CsrPlugin_jumpInterface_payload;
  wire  CsrPlugin_exceptionPendings_0;
  wire  CsrPlugin_exceptionPendings_1;
  wire  CsrPlugin_exceptionPendings_2;
  wire  CsrPlugin_exceptionPendings_3;
  wire  externalInterrupt;
  wire  contextSwitching;
  reg [1:0] CsrPlugin_privilege;
  wire  CsrPlugin_forceMachineWire;
  wire  CsrPlugin_allowInterrupts;
  wire  CsrPlugin_allowException;
  wire  IBusSimplePlugin_jump_pcLoad_valid;
  wire [31:0] IBusSimplePlugin_jump_pcLoad_payload;
  wire [3:0] _zz_91_;
  wire [3:0] _zz_92_;
  wire  _zz_93_;
  wire  _zz_94_;
  wire  _zz_95_;
  wire  IBusSimplePlugin_fetchPc_preOutput_valid;
  wire  IBusSimplePlugin_fetchPc_preOutput_ready;
  wire [31:0] IBusSimplePlugin_fetchPc_preOutput_payload;
  wire  _zz_96_;
  wire  IBusSimplePlugin_fetchPc_output_valid;
  wire  IBusSimplePlugin_fetchPc_output_ready;
  wire [31:0] IBusSimplePlugin_fetchPc_output_payload;
  reg [31:0] IBusSimplePlugin_fetchPc_pcReg /* verilator public */ ;
  reg  IBusSimplePlugin_fetchPc_inc;
  reg  IBusSimplePlugin_fetchPc_propagatePc;
  reg [31:0] IBusSimplePlugin_fetchPc_pc;
  reg  IBusSimplePlugin_fetchPc_samplePcNext;
  reg  _zz_97_;
  reg [31:0] IBusSimplePlugin_decodePc_pcReg /* verilator public */ ;
  wire [31:0] IBusSimplePlugin_decodePc_pcPlus;
  wire  IBusSimplePlugin_decodePc_injectedDecode;
  reg  IBusSimplePlugin_iBusRsp_stages_0_input_valid;
  reg  IBusSimplePlugin_iBusRsp_stages_0_input_ready;
  wire [31:0] IBusSimplePlugin_iBusRsp_stages_0_input_payload;
  wire  IBusSimplePlugin_iBusRsp_stages_0_output_valid;
  wire  IBusSimplePlugin_iBusRsp_stages_0_output_ready;
  wire [31:0] IBusSimplePlugin_iBusRsp_stages_0_output_payload;
  reg  IBusSimplePlugin_iBusRsp_stages_0_halt;
  wire  IBusSimplePlugin_iBusRsp_stages_0_inputSample;
  wire  IBusSimplePlugin_iBusRsp_stages_1_input_valid;
  wire  IBusSimplePlugin_iBusRsp_stages_1_input_ready;
  wire [31:0] IBusSimplePlugin_iBusRsp_stages_1_input_payload;
  wire  IBusSimplePlugin_iBusRsp_stages_1_output_valid;
  wire  IBusSimplePlugin_iBusRsp_stages_1_output_ready;
  wire [31:0] IBusSimplePlugin_iBusRsp_stages_1_output_payload;
  wire  IBusSimplePlugin_iBusRsp_stages_1_halt;
  wire  IBusSimplePlugin_iBusRsp_stages_1_inputSample;
  wire  _zz_98_;
  wire  _zz_99_;
  wire  _zz_100_;
  wire  _zz_101_;
  reg  _zz_102_;
  reg  IBusSimplePlugin_iBusRsp_readyForError;
  wire  IBusSimplePlugin_iBusRsp_output_valid;
  wire  IBusSimplePlugin_iBusRsp_output_ready;
  wire [31:0] IBusSimplePlugin_iBusRsp_output_payload_pc;
  wire  IBusSimplePlugin_iBusRsp_output_payload_rsp_error;
  wire [31:0] IBusSimplePlugin_iBusRsp_output_payload_rsp_inst;
  wire  IBusSimplePlugin_iBusRsp_output_payload_isRvc;
  wire  IBusSimplePlugin_decompressor_inputBeforeStage_valid;
  wire  IBusSimplePlugin_decompressor_inputBeforeStage_ready;
  wire [31:0] IBusSimplePlugin_decompressor_inputBeforeStage_payload_pc;
  wire  IBusSimplePlugin_decompressor_inputBeforeStage_payload_rsp_error;
  wire [31:0] IBusSimplePlugin_decompressor_inputBeforeStage_payload_rsp_inst;
  wire  IBusSimplePlugin_decompressor_inputBeforeStage_payload_isRvc;
  reg  IBusSimplePlugin_decompressor_bufferValid;
  reg [15:0] IBusSimplePlugin_decompressor_bufferData;
  wire [31:0] IBusSimplePlugin_decompressor_raw;
  wire  IBusSimplePlugin_decompressor_isRvc;
  wire [15:0] _zz_103_;
  reg [31:0] IBusSimplePlugin_decompressor_decompressed;
  wire [4:0] _zz_104_;
  wire [4:0] _zz_105_;
  wire [11:0] _zz_106_;
  wire  _zz_107_;
  reg [11:0] _zz_108_;
  wire  _zz_109_;
  reg [9:0] _zz_110_;
  wire [20:0] _zz_111_;
  wire  _zz_112_;
  reg [14:0] _zz_113_;
  wire  _zz_114_;
  reg [2:0] _zz_115_;
  wire  _zz_116_;
  reg [9:0] _zz_117_;
  wire [20:0] _zz_118_;
  wire  _zz_119_;
  reg [4:0] _zz_120_;
  wire [12:0] _zz_121_;
  wire [4:0] _zz_122_;
  wire [4:0] _zz_123_;
  wire [4:0] _zz_124_;
  wire  _zz_125_;
  reg [2:0] _zz_126_;
  reg [2:0] _zz_127_;
  wire  _zz_128_;
  reg [6:0] _zz_129_;
  wire  IBusSimplePlugin_injector_decodeInput_valid;
  wire  IBusSimplePlugin_injector_decodeInput_ready;
  wire [31:0] IBusSimplePlugin_injector_decodeInput_payload_pc;
  wire  IBusSimplePlugin_injector_decodeInput_payload_rsp_error;
  wire [31:0] IBusSimplePlugin_injector_decodeInput_payload_rsp_inst;
  wire  IBusSimplePlugin_injector_decodeInput_payload_isRvc;
  reg  _zz_130_;
  reg [31:0] _zz_131_;
  reg  _zz_132_;
  reg [31:0] _zz_133_;
  reg  _zz_134_;
  reg  IBusSimplePlugin_injector_nextPcCalc_valids_0;
  reg  IBusSimplePlugin_injector_nextPcCalc_valids_1;
  reg  IBusSimplePlugin_injector_nextPcCalc_valids_2;
  reg  IBusSimplePlugin_injector_nextPcCalc_valids_3;
  reg  IBusSimplePlugin_injector_decodeRemoved;
  reg [31:0] IBusSimplePlugin_injector_formal_rawInDecode;
  reg  IBusSimplePlugin_cmd_valid;
  wire  IBusSimplePlugin_cmd_ready;
  wire [31:0] IBusSimplePlugin_cmd_payload_pc;
  reg [2:0] IBusSimplePlugin_pendingCmd;
  wire [2:0] IBusSimplePlugin_pendingCmdNext;
  reg [31:0] IBusSimplePlugin_mmu_joinCtx_physicalAddress;
  reg  IBusSimplePlugin_mmu_joinCtx_isIoAccess;
  reg  IBusSimplePlugin_mmu_joinCtx_allowRead;
  reg  IBusSimplePlugin_mmu_joinCtx_allowWrite;
  reg  IBusSimplePlugin_mmu_joinCtx_allowExecute;
  reg  IBusSimplePlugin_mmu_joinCtx_exception;
  reg  IBusSimplePlugin_mmu_joinCtx_refilling;
  reg [2:0] IBusSimplePlugin_rspJoin_discardCounter;
  wire  IBusSimplePlugin_rspJoin_rspBufferOutput_valid;
  wire  IBusSimplePlugin_rspJoin_rspBufferOutput_ready;
  wire  IBusSimplePlugin_rspJoin_rspBufferOutput_payload_error;
  wire [31:0] IBusSimplePlugin_rspJoin_rspBufferOutput_payload_inst;
  wire  iBus_rsp_takeWhen_valid;
  wire  iBus_rsp_takeWhen_payload_error;
  wire [31:0] iBus_rsp_takeWhen_payload_inst;
  wire [31:0] IBusSimplePlugin_rspJoin_fetchRsp_pc;
  reg  IBusSimplePlugin_rspJoin_fetchRsp_rsp_error;
  wire [31:0] IBusSimplePlugin_rspJoin_fetchRsp_rsp_inst;
  wire  IBusSimplePlugin_rspJoin_fetchRsp_isRvc;
  wire  IBusSimplePlugin_rspJoin_join_valid;
  wire  IBusSimplePlugin_rspJoin_join_ready;
  wire [31:0] IBusSimplePlugin_rspJoin_join_payload_pc;
  wire  IBusSimplePlugin_rspJoin_join_payload_rsp_error;
  wire [31:0] IBusSimplePlugin_rspJoin_join_payload_rsp_inst;
  wire  IBusSimplePlugin_rspJoin_join_payload_isRvc;
  reg  IBusSimplePlugin_rspJoin_exceptionDetected;
  reg  IBusSimplePlugin_rspJoin_redoRequired;
  wire  _zz_135_;
  wire  dBus_cmd_valid;
  wire  dBus_cmd_ready;
  wire  dBus_cmd_payload_wr;
  wire [31:0] dBus_cmd_payload_address;
  wire [31:0] dBus_cmd_payload_data;
  wire [1:0] dBus_cmd_payload_size;
  wire  dBus_rsp_ready;
  wire  dBus_rsp_error;
  wire [31:0] dBus_rsp_data;
  wire  _zz_136_;
  reg  execute_DBusSimplePlugin_skipCmd;
  reg [31:0] _zz_137_;
  reg [3:0] _zz_138_;
  wire [3:0] execute_DBusSimplePlugin_formalMask;
  reg [31:0] writeBack_DBusSimplePlugin_rspShifted;
  wire  _zz_139_;
  reg [31:0] _zz_140_;
  wire  _zz_141_;
  reg [31:0] _zz_142_;
  reg [31:0] writeBack_DBusSimplePlugin_rspFormated;
  wire [24:0] _zz_143_;
  wire  _zz_144_;
  wire  _zz_145_;
  wire  _zz_146_;
  wire  _zz_147_;
  wire `Src1CtrlEnum_defaultEncoding_type _zz_148_;
  wire `BranchCtrlEnum_defaultEncoding_type _zz_149_;
  wire `Src2CtrlEnum_defaultEncoding_type _zz_150_;
  wire `AluCtrlEnum_defaultEncoding_type _zz_151_;
  wire `EnvCtrlEnum_defaultEncoding_type _zz_152_;
  wire `AluBitwiseCtrlEnum_defaultEncoding_type _zz_153_;
  wire `ShiftCtrlEnum_defaultEncoding_type _zz_154_;
  wire [4:0] decode_RegFilePlugin_regFileReadAddress1;
  wire [4:0] decode_RegFilePlugin_regFileReadAddress2;
  wire [31:0] decode_RegFilePlugin_rs1Data;
  wire [31:0] decode_RegFilePlugin_rs2Data;
  reg  lastStageRegFileWrite_valid /* verilator public */ ;
  wire [4:0] lastStageRegFileWrite_payload_address /* verilator public */ ;
  wire [31:0] lastStageRegFileWrite_payload_data /* verilator public */ ;
  reg  _zz_155_;
  reg [31:0] execute_IntAluPlugin_bitwise;
  reg [31:0] _zz_156_;
  reg [31:0] _zz_157_;
  wire  _zz_158_;
  reg [19:0] _zz_159_;
  wire  _zz_160_;
  reg [19:0] _zz_161_;
  reg [31:0] _zz_162_;
  reg [31:0] execute_SrcPlugin_addSub;
  wire  execute_SrcPlugin_less;
  reg  execute_LightShifterPlugin_isActive;
  wire  execute_LightShifterPlugin_isShift;
  reg [4:0] execute_LightShifterPlugin_amplitudeReg;
  wire [4:0] execute_LightShifterPlugin_amplitude;
  wire [31:0] execute_LightShifterPlugin_shiftInput;
  wire  execute_LightShifterPlugin_done;
  reg [31:0] _zz_163_;
  reg  _zz_164_;
  reg  _zz_165_;
  wire  _zz_166_;
  reg  _zz_167_;
  reg [4:0] _zz_168_;
  wire  execute_BranchPlugin_eq;
  wire [2:0] _zz_169_;
  reg  _zz_170_;
  reg  _zz_171_;
  wire [31:0] execute_BranchPlugin_branch_src1;
  wire  _zz_172_;
  reg [10:0] _zz_173_;
  wire  _zz_174_;
  reg [19:0] _zz_175_;
  wire  _zz_176_;
  reg [18:0] _zz_177_;
  reg [31:0] _zz_178_;
  wire [31:0] execute_BranchPlugin_branch_src2;
  wire [31:0] execute_BranchPlugin_branchAdder;
  wire [1:0] CsrPlugin_misa_base;
  wire [25:0] CsrPlugin_misa_extensions;
  reg [1:0] CsrPlugin_mtvec_mode;
  reg [29:0] CsrPlugin_mtvec_base;
  reg [31:0] CsrPlugin_mepc;
  reg  CsrPlugin_mstatus_MIE;
  reg  CsrPlugin_mstatus_MPIE;
  reg [1:0] CsrPlugin_mstatus_MPP;
  reg  CsrPlugin_mip_MEIP;
  reg  CsrPlugin_mip_MTIP;
  reg  CsrPlugin_mip_MSIP;
  reg  CsrPlugin_mie_MEIE;
  reg  CsrPlugin_mie_MTIE;
  reg  CsrPlugin_mie_MSIE;
  reg  CsrPlugin_mcause_interrupt;
  reg [3:0] CsrPlugin_mcause_exceptionCode;
  reg [31:0] CsrPlugin_mtval;
  reg [63:0] CsrPlugin_mcycle = 64'b0000000000000000000000000000000000000000000000000000000000000000;
  reg [63:0] CsrPlugin_minstret = 64'b0000000000000000000000000000000000000000000000000000000000000000;
  wire  _zz_179_;
  wire  _zz_180_;
  wire  _zz_181_;
  reg  CsrPlugin_exceptionPortCtrl_exceptionValids_decode;
  reg  CsrPlugin_exceptionPortCtrl_exceptionValids_execute;
  reg  CsrPlugin_exceptionPortCtrl_exceptionValids_memory;
  reg  CsrPlugin_exceptionPortCtrl_exceptionValids_writeBack;
  reg  CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_decode;
  reg  CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_execute;
  reg  CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_memory;
  reg  CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_writeBack;
  reg [3:0] CsrPlugin_exceptionPortCtrl_exceptionContext_code;
  reg [31:0] CsrPlugin_exceptionPortCtrl_exceptionContext_badAddr;
  wire [1:0] CsrPlugin_exceptionPortCtrl_exceptionTargetPrivilegeUncapped;
  wire [1:0] CsrPlugin_exceptionPortCtrl_exceptionTargetPrivilege;
  wire [1:0] _zz_182_;
  wire  _zz_183_;
  reg  CsrPlugin_interrupt_valid;
  reg [3:0] CsrPlugin_interrupt_code /* verilator public */ ;
  reg [1:0] CsrPlugin_interrupt_targetPrivilege;
  wire  CsrPlugin_exception;
  wire  CsrPlugin_lastStageWasWfi;
  reg  CsrPlugin_pipelineLiberator_done;
  wire  CsrPlugin_interruptJump /* verilator public */ ;
  reg  CsrPlugin_hadException;
  reg [1:0] CsrPlugin_targetPrivilege;
  reg [3:0] CsrPlugin_trapCause;
  reg [1:0] CsrPlugin_xtvec_mode;
  reg [29:0] CsrPlugin_xtvec_base;
  wire  execute_CsrPlugin_inWfi /* verilator public */ ;
  reg  execute_CsrPlugin_wfiWake;
  wire  execute_CsrPlugin_blockedBySideEffects;
  reg  execute_CsrPlugin_illegalAccess;
  reg  execute_CsrPlugin_illegalInstruction;
  reg [31:0] execute_CsrPlugin_readData;
  wire  execute_CsrPlugin_writeInstruction;
  wire  execute_CsrPlugin_readInstruction;
  wire  execute_CsrPlugin_writeEnable;
  wire  execute_CsrPlugin_readEnable;
  wire [31:0] execute_CsrPlugin_readToWriteData;
  reg [31:0] execute_CsrPlugin_writeData;
  wire [11:0] execute_CsrPlugin_csrAddress;
  reg [31:0] externalInterruptArray_regNext;
  reg [31:0] _zz_184_;
  wire [31:0] _zz_185_;
  reg  decode_to_execute_CSR_WRITE_OPCODE;
  reg `BranchCtrlEnum_defaultEncoding_type decode_to_execute_BRANCH_CTRL;
  reg  decode_to_execute_MEMORY_STORE;
  reg  execute_to_memory_MEMORY_STORE;
  reg  memory_to_writeBack_MEMORY_STORE;
  reg  decode_to_execute_MEMORY_ENABLE;
  reg  execute_to_memory_MEMORY_ENABLE;
  reg  memory_to_writeBack_MEMORY_ENABLE;
  reg  decode_to_execute_CSR_READ_OPCODE;
  reg  execute_to_memory_MMU_FAULT;
  reg  decode_to_execute_IS_RVC;
  reg  decode_to_execute_BYPASSABLE_EXECUTE_STAGE;
  reg  decode_to_execute_BYPASSABLE_MEMORY_STAGE;
  reg  execute_to_memory_BYPASSABLE_MEMORY_STAGE;
  reg  decode_to_execute_SRC_LESS_UNSIGNED;
  reg `ShiftCtrlEnum_defaultEncoding_type decode_to_execute_SHIFT_CTRL;
  reg  execute_to_memory_BRANCH_DO;
  reg  execute_to_memory_ALIGNEMENT_FAULT;
  reg `AluCtrlEnum_defaultEncoding_type decode_to_execute_ALU_CTRL;
  reg  decode_to_execute_IS_CSR;
  reg `EnvCtrlEnum_defaultEncoding_type decode_to_execute_ENV_CTRL;
  reg `EnvCtrlEnum_defaultEncoding_type execute_to_memory_ENV_CTRL;
  reg `EnvCtrlEnum_defaultEncoding_type memory_to_writeBack_ENV_CTRL;
  reg [31:0] decode_to_execute_INSTRUCTION;
  reg [31:0] execute_to_memory_INSTRUCTION;
  reg [31:0] memory_to_writeBack_INSTRUCTION;
  reg [31:0] decode_to_execute_PC;
  reg [31:0] execute_to_memory_PC;
  reg [31:0] memory_to_writeBack_PC;
  reg  decode_to_execute_SRC2_FORCE_ZERO;
  reg [31:0] decode_to_execute_RS1;
  reg `Src2CtrlEnum_defaultEncoding_type decode_to_execute_SRC2_CTRL;
  reg  decode_to_execute_SRC_USE_SUB_LESS;
  reg [31:0] decode_to_execute_FORMAL_PC_NEXT;
  reg [31:0] execute_to_memory_FORMAL_PC_NEXT;
  reg [31:0] memory_to_writeBack_FORMAL_PC_NEXT;
  reg `Src1CtrlEnum_defaultEncoding_type decode_to_execute_SRC1_CTRL;
  reg `AluBitwiseCtrlEnum_defaultEncoding_type decode_to_execute_ALU_BITWISE_CTRL;
  reg [31:0] execute_to_memory_BRANCH_CALC;
  reg [31:0] memory_to_writeBack_MEMORY_READ_DATA;
  reg [31:0] execute_to_memory_REGFILE_WRITE_DATA;
  reg [31:0] memory_to_writeBack_REGFILE_WRITE_DATA;
  reg  decode_to_execute_REGFILE_WRITE_VALID;
  reg  execute_to_memory_REGFILE_WRITE_VALID;
  reg  memory_to_writeBack_REGFILE_WRITE_VALID;
  reg [1:0] execute_to_memory_MEMORY_ADDRESS_LOW;
  reg [1:0] memory_to_writeBack_MEMORY_ADDRESS_LOW;
  reg [31:0] execute_to_memory_MMU_RSP_physicalAddress;
  reg  execute_to_memory_MMU_RSP_isIoAccess;
  reg  execute_to_memory_MMU_RSP_allowRead;
  reg  execute_to_memory_MMU_RSP_allowWrite;
  reg  execute_to_memory_MMU_RSP_allowExecute;
  reg  execute_to_memory_MMU_RSP_exception;
  reg  execute_to_memory_MMU_RSP_refilling;
  reg [31:0] decode_to_execute_RS2;
  wire  iBus_cmd_m2sPipe_valid;
  wire  iBus_cmd_m2sPipe_ready;
  wire [31:0] iBus_cmd_m2sPipe_payload_pc;
  reg  _zz_186_;
  reg [31:0] _zz_187_;
  wire  dBus_cmd_halfPipe_valid;
  wire  dBus_cmd_halfPipe_ready;
  wire  dBus_cmd_halfPipe_payload_wr;
  wire [31:0] dBus_cmd_halfPipe_payload_address;
  wire [31:0] dBus_cmd_halfPipe_payload_data;
  wire [1:0] dBus_cmd_halfPipe_payload_size;
  reg  dBus_cmd_halfPipe_regs_valid;
  reg  dBus_cmd_halfPipe_regs_ready;
  reg  dBus_cmd_halfPipe_regs_payload_wr;
  reg [31:0] dBus_cmd_halfPipe_regs_payload_address;
  reg [31:0] dBus_cmd_halfPipe_regs_payload_data;
  reg [1:0] dBus_cmd_halfPipe_regs_payload_size;
  reg [3:0] _zz_188_;
  `ifndef SYNTHESIS
  reg [39:0] decode_ALU_BITWISE_CTRL_string;
  reg [39:0] _zz_1__string;
  reg [39:0] _zz_2__string;
  reg [39:0] _zz_3__string;
  reg [95:0] decode_SRC1_CTRL_string;
  reg [95:0] _zz_4__string;
  reg [95:0] _zz_5__string;
  reg [95:0] _zz_6__string;
  reg [23:0] decode_SRC2_CTRL_string;
  reg [23:0] _zz_7__string;
  reg [23:0] _zz_8__string;
  reg [23:0] _zz_9__string;
  reg [31:0] _zz_10__string;
  reg [31:0] _zz_11__string;
  reg [31:0] _zz_12__string;
  reg [31:0] _zz_13__string;
  reg [31:0] decode_ENV_CTRL_string;
  reg [31:0] _zz_14__string;
  reg [31:0] _zz_15__string;
  reg [31:0] _zz_16__string;
  reg [63:0] decode_ALU_CTRL_string;
  reg [63:0] _zz_17__string;
  reg [63:0] _zz_18__string;
  reg [63:0] _zz_19__string;
  reg [71:0] decode_SHIFT_CTRL_string;
  reg [71:0] _zz_20__string;
  reg [71:0] _zz_21__string;
  reg [71:0] _zz_22__string;
  reg [31:0] decode_BRANCH_CTRL_string;
  reg [31:0] _zz_23__string;
  reg [31:0] _zz_24__string;
  reg [31:0] _zz_25__string;
  reg [31:0] memory_ENV_CTRL_string;
  reg [31:0] _zz_26__string;
  reg [31:0] execute_ENV_CTRL_string;
  reg [31:0] _zz_27__string;
  reg [31:0] writeBack_ENV_CTRL_string;
  reg [31:0] _zz_30__string;
  reg [31:0] execute_BRANCH_CTRL_string;
  reg [31:0] _zz_32__string;
  reg [71:0] execute_SHIFT_CTRL_string;
  reg [71:0] _zz_35__string;
  reg [23:0] execute_SRC2_CTRL_string;
  reg [23:0] _zz_40__string;
  reg [95:0] execute_SRC1_CTRL_string;
  reg [95:0] _zz_42__string;
  reg [63:0] execute_ALU_CTRL_string;
  reg [63:0] _zz_45__string;
  reg [39:0] execute_ALU_BITWISE_CTRL_string;
  reg [39:0] _zz_47__string;
  reg [71:0] _zz_55__string;
  reg [39:0] _zz_57__string;
  reg [31:0] _zz_59__string;
  reg [63:0] _zz_60__string;
  reg [23:0] _zz_61__string;
  reg [31:0] _zz_69__string;
  reg [95:0] _zz_70__string;
  reg [95:0] _zz_148__string;
  reg [31:0] _zz_149__string;
  reg [23:0] _zz_150__string;
  reg [63:0] _zz_151__string;
  reg [31:0] _zz_152__string;
  reg [39:0] _zz_153__string;
  reg [71:0] _zz_154__string;
  reg [31:0] decode_to_execute_BRANCH_CTRL_string;
  reg [71:0] decode_to_execute_SHIFT_CTRL_string;
  reg [63:0] decode_to_execute_ALU_CTRL_string;
  reg [31:0] decode_to_execute_ENV_CTRL_string;
  reg [31:0] execute_to_memory_ENV_CTRL_string;
  reg [31:0] memory_to_writeBack_ENV_CTRL_string;
  reg [23:0] decode_to_execute_SRC2_CTRL_string;
  reg [95:0] decode_to_execute_SRC1_CTRL_string;
  reg [39:0] decode_to_execute_ALU_BITWISE_CTRL_string;
  `endif

  (* ram_style = "block" *) reg [31:0] RegFilePlugin_regFile [0:31] /* verilator public */ ;
  assign _zz_193_ = ((execute_arbitration_isValid && execute_LightShifterPlugin_isShift) && (execute_SRC2[4 : 0] != (5'b00000)));
  assign _zz_194_ = (execute_arbitration_isValid && execute_IS_CSR);
  assign _zz_195_ = ({decodeExceptionPort_valid,IBusSimplePlugin_decodeExceptionPort_valid} != (2'b00));
  assign _zz_196_ = (! execute_arbitration_isStuckByOthers);
  assign _zz_197_ = (CsrPlugin_hadException || CsrPlugin_interruptJump);
  assign _zz_198_ = (writeBack_arbitration_isValid && (writeBack_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET));
  assign _zz_199_ = writeBack_INSTRUCTION[29 : 28];
  assign _zz_200_ = (IBusSimplePlugin_fetchPc_preOutput_valid && IBusSimplePlugin_fetchPc_preOutput_ready);
  assign _zz_201_ = (IBusSimplePlugin_mmuBus_rsp_exception || IBusSimplePlugin_mmuBus_rsp_refilling);
  assign _zz_202_ = ((IBusSimplePlugin_iBusRsp_stages_1_input_valid && (! IBusSimplePlugin_mmu_joinCtx_refilling)) && (IBusSimplePlugin_mmu_joinCtx_exception || (! IBusSimplePlugin_mmu_joinCtx_allowExecute)));
  assign _zz_203_ = ((dBus_rsp_ready && dBus_rsp_error) && (! memory_MEMORY_STORE));
  assign _zz_204_ = (! ((memory_arbitration_isValid && memory_MEMORY_ENABLE) && (1'b1 || (! memory_arbitration_isStuckByOthers))));
  assign _zz_205_ = (writeBack_arbitration_isValid && writeBack_REGFILE_WRITE_VALID);
  assign _zz_206_ = (1'b1 || (! 1'b1));
  assign _zz_207_ = (memory_arbitration_isValid && memory_REGFILE_WRITE_VALID);
  assign _zz_208_ = (1'b1 || (! memory_BYPASSABLE_MEMORY_STAGE));
  assign _zz_209_ = (execute_arbitration_isValid && execute_REGFILE_WRITE_VALID);
  assign _zz_210_ = (1'b1 || (! execute_BYPASSABLE_EXECUTE_STAGE));
  assign _zz_211_ = (IBusSimplePlugin_iBusRsp_output_valid && IBusSimplePlugin_iBusRsp_output_ready);
  assign _zz_212_ = (CsrPlugin_mstatus_MIE || (CsrPlugin_privilege < (2'b11)));
  assign _zz_213_ = ((_zz_179_ && 1'b1) && (! 1'b0));
  assign _zz_214_ = ((_zz_180_ && 1'b1) && (! 1'b0));
  assign _zz_215_ = ((_zz_181_ && 1'b1) && (! 1'b0));
  assign _zz_216_ = (! dBus_cmd_halfPipe_regs_valid);
  assign _zz_217_ = {_zz_103_[1 : 0],_zz_103_[15 : 13]};
  assign _zz_218_ = _zz_103_[6 : 5];
  assign _zz_219_ = _zz_103_[11 : 10];
  assign _zz_220_ = writeBack_INSTRUCTION[13 : 12];
  assign _zz_221_ = execute_INSTRUCTION[13];
  assign _zz_222_ = (_zz_91_ - (4'b0001));
  assign _zz_223_ = {IBusSimplePlugin_fetchPc_inc,(2'b00)};
  assign _zz_224_ = {29'd0, _zz_223_};
  assign _zz_225_ = (decode_IS_RVC ? (3'b010) : (3'b100));
  assign _zz_226_ = {29'd0, _zz_225_};
  assign _zz_227_ = {{_zz_113_,_zz_103_[6 : 2]},(12'b000000000000)};
  assign _zz_228_ = {{{(4'b0000),_zz_103_[8 : 7]},_zz_103_[12 : 9]},(2'b00)};
  assign _zz_229_ = {{{(4'b0000),_zz_103_[8 : 7]},_zz_103_[12 : 9]},(2'b00)};
  assign _zz_230_ = (decode_IS_RVC ? (3'b010) : (3'b100));
  assign _zz_231_ = {29'd0, _zz_230_};
  assign _zz_232_ = (IBusSimplePlugin_pendingCmd + _zz_234_);
  assign _zz_233_ = (IBusSimplePlugin_cmd_valid && IBusSimplePlugin_cmd_ready);
  assign _zz_234_ = {2'd0, _zz_233_};
  assign _zz_235_ = iBus_rsp_valid;
  assign _zz_236_ = {2'd0, _zz_235_};
  assign _zz_237_ = (iBus_rsp_valid && (IBusSimplePlugin_rspJoin_discardCounter != (3'b000)));
  assign _zz_238_ = {2'd0, _zz_237_};
  assign _zz_239_ = iBus_rsp_valid;
  assign _zz_240_ = {2'd0, _zz_239_};
  assign _zz_241_ = (memory_MEMORY_STORE ? (3'b110) : (3'b100));
  assign _zz_242_ = _zz_143_[4 : 4];
  assign _zz_243_ = _zz_143_[5 : 5];
  assign _zz_244_ = _zz_143_[6 : 6];
  assign _zz_245_ = _zz_143_[7 : 7];
  assign _zz_246_ = _zz_143_[8 : 8];
  assign _zz_247_ = _zz_143_[10 : 10];
  assign _zz_248_ = _zz_143_[11 : 11];
  assign _zz_249_ = _zz_143_[17 : 17];
  assign _zz_250_ = _zz_143_[20 : 20];
  assign _zz_251_ = _zz_143_[23 : 23];
  assign _zz_252_ = _zz_143_[24 : 24];
  assign _zz_253_ = execute_SRC_LESS;
  assign _zz_254_ = (execute_IS_RVC ? (3'b010) : (3'b100));
  assign _zz_255_ = execute_INSTRUCTION[19 : 15];
  assign _zz_256_ = execute_INSTRUCTION[31 : 20];
  assign _zz_257_ = {execute_INSTRUCTION[31 : 25],execute_INSTRUCTION[11 : 7]};
  assign _zz_258_ = ($signed(_zz_259_) + $signed(_zz_262_));
  assign _zz_259_ = ($signed(_zz_260_) + $signed(_zz_261_));
  assign _zz_260_ = execute_SRC1;
  assign _zz_261_ = (execute_SRC_USE_SUB_LESS ? (~ execute_SRC2) : execute_SRC2);
  assign _zz_262_ = (execute_SRC_USE_SUB_LESS ? _zz_263_ : _zz_264_);
  assign _zz_263_ = (32'b00000000000000000000000000000001);
  assign _zz_264_ = (32'b00000000000000000000000000000000);
  assign _zz_265_ = (_zz_266_ >>> 1);
  assign _zz_266_ = {((execute_SHIFT_CTRL == `ShiftCtrlEnum_defaultEncoding_SRA_1) && execute_LightShifterPlugin_shiftInput[31]),execute_LightShifterPlugin_shiftInput};
  assign _zz_267_ = {{{execute_INSTRUCTION[31],execute_INSTRUCTION[19 : 12]},execute_INSTRUCTION[20]},execute_INSTRUCTION[30 : 21]};
  assign _zz_268_ = execute_INSTRUCTION[31 : 20];
  assign _zz_269_ = {{{execute_INSTRUCTION[31],execute_INSTRUCTION[7]},execute_INSTRUCTION[30 : 25]},execute_INSTRUCTION[11 : 8]};
  assign _zz_270_ = (_zz_182_ & (~ _zz_271_));
  assign _zz_271_ = (_zz_182_ - (2'b01));
  assign _zz_272_ = execute_CsrPlugin_writeData[7 : 7];
  assign _zz_273_ = execute_CsrPlugin_writeData[3 : 3];
  assign _zz_274_ = execute_CsrPlugin_writeData[3 : 3];
  assign _zz_275_ = execute_CsrPlugin_writeData[11 : 11];
  assign _zz_276_ = execute_CsrPlugin_writeData[7 : 7];
  assign _zz_277_ = execute_CsrPlugin_writeData[3 : 3];
  assign _zz_278_ = ({3'd0,_zz_188_} <<< dBus_cmd_halfPipe_payload_address[1 : 0]);
  assign _zz_279_ = 1'b1;
  assign _zz_280_ = 1'b1;
  assign _zz_281_ = {_zz_95_,_zz_94_};
  assign _zz_282_ = (_zz_103_[11 : 10] == (2'b01));
  assign _zz_283_ = ((_zz_103_[11 : 10] == (2'b11)) && (_zz_103_[6 : 5] == (2'b00)));
  assign _zz_284_ = (7'b0000000);
  assign _zz_285_ = _zz_103_[6 : 2];
  assign _zz_286_ = _zz_103_[12];
  assign _zz_287_ = _zz_103_[11 : 7];
  assign _zz_288_ = (32'b00000000000000000000000001011000);
  assign _zz_289_ = ((decode_INSTRUCTION & (32'b00000000000000000001000001010000)) == (32'b00000000000000000001000001010000));
  assign _zz_290_ = ((decode_INSTRUCTION & (32'b00000000000000000010000001010000)) == (32'b00000000000000000010000001010000));
  assign _zz_291_ = ((decode_INSTRUCTION & (32'b00000000000000000111000001010100)) == (32'b00000000000000000101000000010000));
  assign _zz_292_ = {(_zz_297_ == _zz_298_),(_zz_299_ == _zz_300_)};
  assign _zz_293_ = (2'b00);
  assign _zz_294_ = ({_zz_301_,_zz_302_} != (2'b00));
  assign _zz_295_ = (_zz_303_ != (1'b0));
  assign _zz_296_ = {(_zz_304_ != _zz_305_),{_zz_306_,{_zz_307_,_zz_308_}}};
  assign _zz_297_ = (decode_INSTRUCTION & (32'b01000000000000000011000001010100));
  assign _zz_298_ = (32'b01000000000000000001000000010000);
  assign _zz_299_ = (decode_INSTRUCTION & (32'b00000000000000000111000001010100));
  assign _zz_300_ = (32'b00000000000000000001000000010000);
  assign _zz_301_ = ((decode_INSTRUCTION & (32'b00000000000000000000000000110100)) == (32'b00000000000000000000000000100000));
  assign _zz_302_ = ((decode_INSTRUCTION & (32'b00000000000000000000000001100100)) == (32'b00000000000000000000000000100000));
  assign _zz_303_ = ((decode_INSTRUCTION & (32'b00000000000000000001000000000000)) == (32'b00000000000000000001000000000000));
  assign _zz_304_ = ((decode_INSTRUCTION & _zz_309_) == (32'b00000000000000000010000000000000));
  assign _zz_305_ = (1'b0);
  assign _zz_306_ = ((_zz_310_ == _zz_311_) != (1'b0));
  assign _zz_307_ = (_zz_312_ != (1'b0));
  assign _zz_308_ = {(_zz_313_ != _zz_314_),{_zz_315_,{_zz_316_,_zz_317_}}};
  assign _zz_309_ = (32'b00000000000000000011000000000000);
  assign _zz_310_ = (decode_INSTRUCTION & (32'b00000000000000000000000000010000));
  assign _zz_311_ = (32'b00000000000000000000000000010000);
  assign _zz_312_ = ((decode_INSTRUCTION & (32'b00000000000000000011000001010000)) == (32'b00000000000000000000000001010000));
  assign _zz_313_ = {(_zz_318_ == _zz_319_),(_zz_320_ == _zz_321_)};
  assign _zz_314_ = (2'b00);
  assign _zz_315_ = ((_zz_322_ == _zz_323_) != (1'b0));
  assign _zz_316_ = ({_zz_324_,_zz_325_} != (2'b00));
  assign _zz_317_ = {(_zz_326_ != _zz_327_),{_zz_328_,{_zz_329_,_zz_330_}}};
  assign _zz_318_ = (decode_INSTRUCTION & (32'b00000000000000000110000000010100));
  assign _zz_319_ = (32'b00000000000000000110000000010000);
  assign _zz_320_ = (decode_INSTRUCTION & (32'b00000000000000000101000000010100));
  assign _zz_321_ = (32'b00000000000000000100000000010000);
  assign _zz_322_ = (decode_INSTRUCTION & (32'b00000000000000000110000000010100));
  assign _zz_323_ = (32'b00000000000000000010000000010000);
  assign _zz_324_ = _zz_147_;
  assign _zz_325_ = ((decode_INSTRUCTION & _zz_331_) == (32'b00000000000000000000000000100000));
  assign _zz_326_ = {_zz_147_,(_zz_332_ == _zz_333_)};
  assign _zz_327_ = (2'b00);
  assign _zz_328_ = ((_zz_334_ == _zz_335_) != (1'b0));
  assign _zz_329_ = (_zz_146_ != (1'b0));
  assign _zz_330_ = {(_zz_336_ != _zz_337_),{_zz_338_,{_zz_339_,_zz_340_}}};
  assign _zz_331_ = (32'b00000000000000000000000001110000);
  assign _zz_332_ = (decode_INSTRUCTION & (32'b00000000000000000000000000100000));
  assign _zz_333_ = (32'b00000000000000000000000000000000);
  assign _zz_334_ = (decode_INSTRUCTION & (32'b00000000000000000000000000100000));
  assign _zz_335_ = (32'b00000000000000000000000000100000);
  assign _zz_336_ = {(_zz_341_ == _zz_342_),{_zz_343_,_zz_344_}};
  assign _zz_337_ = (3'b000);
  assign _zz_338_ = ({_zz_345_,_zz_346_} != (2'b00));
  assign _zz_339_ = ({_zz_347_,_zz_348_} != (2'b00));
  assign _zz_340_ = {(_zz_349_ != _zz_350_),{_zz_351_,{_zz_352_,_zz_353_}}};
  assign _zz_341_ = (decode_INSTRUCTION & (32'b00000000000000000000000001010000));
  assign _zz_342_ = (32'b00000000000000000000000001000000);
  assign _zz_343_ = ((decode_INSTRUCTION & _zz_354_) == (32'b00000000000000000000000001000000));
  assign _zz_344_ = ((decode_INSTRUCTION & _zz_355_) == (32'b00000000000000000000000000000000));
  assign _zz_345_ = ((decode_INSTRUCTION & _zz_356_) == (32'b00000000000000000010000000000000));
  assign _zz_346_ = ((decode_INSTRUCTION & _zz_357_) == (32'b00000000000000000001000000000000));
  assign _zz_347_ = (_zz_358_ == _zz_359_);
  assign _zz_348_ = (_zz_360_ == _zz_361_);
  assign _zz_349_ = {_zz_362_,{_zz_363_,_zz_364_}};
  assign _zz_350_ = (3'b000);
  assign _zz_351_ = ({_zz_365_,_zz_366_} != (4'b0000));
  assign _zz_352_ = (_zz_367_ != _zz_368_);
  assign _zz_353_ = {_zz_369_,{_zz_370_,_zz_371_}};
  assign _zz_354_ = (32'b00000000000000000011000001000000);
  assign _zz_355_ = (32'b00000000000000000000000000111000);
  assign _zz_356_ = (32'b00000000000000000010000000010000);
  assign _zz_357_ = (32'b00000000000000000101000000000000);
  assign _zz_358_ = (decode_INSTRUCTION & (32'b00000000000000000000000001100100));
  assign _zz_359_ = (32'b00000000000000000000000000100100);
  assign _zz_360_ = (decode_INSTRUCTION & (32'b00000000000000000011000001010100));
  assign _zz_361_ = (32'b00000000000000000001000000010000);
  assign _zz_362_ = ((decode_INSTRUCTION & _zz_372_) == (32'b00000000000000000000000001000000));
  assign _zz_363_ = (_zz_373_ == _zz_374_);
  assign _zz_364_ = (_zz_375_ == _zz_376_);
  assign _zz_365_ = (_zz_377_ == _zz_378_);
  assign _zz_366_ = {_zz_379_,{_zz_380_,_zz_381_}};
  assign _zz_367_ = {_zz_145_,{_zz_382_,_zz_383_}};
  assign _zz_368_ = (6'b000000);
  assign _zz_369_ = ({_zz_384_,_zz_385_} != (2'b00));
  assign _zz_370_ = (_zz_386_ != _zz_387_);
  assign _zz_371_ = {_zz_388_,_zz_389_};
  assign _zz_372_ = (32'b00000000000000000000000001000100);
  assign _zz_373_ = (decode_INSTRUCTION & (32'b00000000000000000010000000010100));
  assign _zz_374_ = (32'b00000000000000000010000000010000);
  assign _zz_375_ = (decode_INSTRUCTION & (32'b01000000000000000100000000110100));
  assign _zz_376_ = (32'b01000000000000000000000000110000);
  assign _zz_377_ = (decode_INSTRUCTION & (32'b00000000000000000000000001000100));
  assign _zz_378_ = (32'b00000000000000000000000000000000);
  assign _zz_379_ = ((decode_INSTRUCTION & _zz_390_) == (32'b00000000000000000000000000000000));
  assign _zz_380_ = (_zz_391_ == _zz_392_);
  assign _zz_381_ = (_zz_393_ == _zz_394_);
  assign _zz_382_ = (_zz_395_ == _zz_396_);
  assign _zz_383_ = {_zz_397_,{_zz_398_,_zz_399_}};
  assign _zz_384_ = _zz_145_;
  assign _zz_385_ = (_zz_400_ == _zz_401_);
  assign _zz_386_ = (_zz_402_ == _zz_403_);
  assign _zz_387_ = (1'b0);
  assign _zz_388_ = ({_zz_404_,_zz_405_} != (2'b00));
  assign _zz_389_ = ({_zz_406_,_zz_407_} != (2'b00));
  assign _zz_390_ = (32'b00000000000000000000000000011000);
  assign _zz_391_ = (decode_INSTRUCTION & (32'b00000000000000000110000000000100));
  assign _zz_392_ = (32'b00000000000000000010000000000000);
  assign _zz_393_ = (decode_INSTRUCTION & (32'b00000000000000000101000000000100));
  assign _zz_394_ = (32'b00000000000000000001000000000000);
  assign _zz_395_ = (decode_INSTRUCTION & (32'b00000000000000000001000000010000));
  assign _zz_396_ = (32'b00000000000000000001000000010000);
  assign _zz_397_ = ((decode_INSTRUCTION & (32'b00000000000000000010000000010000)) == (32'b00000000000000000010000000010000));
  assign _zz_398_ = _zz_146_;
  assign _zz_399_ = {((decode_INSTRUCTION & (32'b00000000000000000000000000001100)) == (32'b00000000000000000000000000000100)),((decode_INSTRUCTION & (32'b00000000000000000000000000101000)) == (32'b00000000000000000000000000000000))};
  assign _zz_400_ = (decode_INSTRUCTION & (32'b00000000000000000000000000011100));
  assign _zz_401_ = (32'b00000000000000000000000000000100);
  assign _zz_402_ = (decode_INSTRUCTION & (32'b00000000000000000000000001011000));
  assign _zz_403_ = (32'b00000000000000000000000001000000);
  assign _zz_404_ = ((decode_INSTRUCTION & (32'b00000000000000000000000000010100)) == (32'b00000000000000000000000000000100));
  assign _zz_405_ = _zz_144_;
  assign _zz_406_ = ((decode_INSTRUCTION & (32'b00000000000000000000000001000100)) == (32'b00000000000000000000000000000100));
  assign _zz_407_ = _zz_144_;
  assign _zz_408_ = (32'b00000000000000000001000001111111);
  assign _zz_409_ = (decode_INSTRUCTION & (32'b00000000000000000010000001111111));
  assign _zz_410_ = (32'b00000000000000000010000001110011);
  assign _zz_411_ = ((decode_INSTRUCTION & (32'b00000000000000000100000001111111)) == (32'b00000000000000000100000001100011));
  assign _zz_412_ = ((decode_INSTRUCTION & (32'b00000000000000000010000001111111)) == (32'b00000000000000000010000000010011));
  assign _zz_413_ = {((decode_INSTRUCTION & (32'b00000000000000000110000000111111)) == (32'b00000000000000000000000000100011)),{((decode_INSTRUCTION & (32'b00000000000000000010000001111111)) == (32'b00000000000000000000000000000011)),{((decode_INSTRUCTION & _zz_414_) == (32'b00000000000000000000000000000011)),{(_zz_415_ == _zz_416_),{_zz_417_,{_zz_418_,_zz_419_}}}}}};
  assign _zz_414_ = (32'b00000000000000000101000001011111);
  assign _zz_415_ = (decode_INSTRUCTION & (32'b00000000000000000111000001111011));
  assign _zz_416_ = (32'b00000000000000000000000001100011);
  assign _zz_417_ = ((decode_INSTRUCTION & (32'b00000000000000000110000001111111)) == (32'b00000000000000000000000000001111));
  assign _zz_418_ = ((decode_INSTRUCTION & (32'b11111110000000000000000001111111)) == (32'b00000000000000000000000000110011));
  assign _zz_419_ = {((decode_INSTRUCTION & (32'b10111100000000000111000001111111)) == (32'b00000000000000000101000000010011)),{((decode_INSTRUCTION & (32'b11111100000000000011000001111111)) == (32'b00000000000000000001000000010011)),{((decode_INSTRUCTION & _zz_420_) == (32'b00000000000000000101000000110011)),{(_zz_421_ == _zz_422_),(_zz_423_ == _zz_424_)}}}};
  assign _zz_420_ = (32'b10111110000000000111000001111111);
  assign _zz_421_ = (decode_INSTRUCTION & (32'b10111110000000000111000001111111));
  assign _zz_422_ = (32'b00000000000000000000000000110011);
  assign _zz_423_ = (decode_INSTRUCTION & (32'b11011111111111111111111111111111));
  assign _zz_424_ = (32'b00010000001000000000000001110011);
  always @ (posedge clk) begin
    if(_zz_50_) begin
      RegFilePlugin_regFile[lastStageRegFileWrite_payload_address] <= lastStageRegFileWrite_payload_data;
    end
  end

  always @ (posedge clk) begin
    if(_zz_279_) begin
      _zz_190_ <= RegFilePlugin_regFile[decode_RegFilePlugin_regFileReadAddress1];
    end
  end

  always @ (posedge clk) begin
    if(_zz_280_) begin
      _zz_191_ <= RegFilePlugin_regFile[decode_RegFilePlugin_regFileReadAddress2];
    end
  end

  StreamFifoLowLatency IBusSimplePlugin_rspJoin_rspBuffer_c ( 
    .io_push_valid(iBus_rsp_takeWhen_valid),
    .io_push_ready(IBusSimplePlugin_rspJoin_rspBuffer_c_io_push_ready),
    .io_push_payload_error(iBus_rsp_takeWhen_payload_error),
    .io_push_payload_inst(iBus_rsp_takeWhen_payload_inst),
    .io_pop_valid(IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_valid),
    .io_pop_ready(IBusSimplePlugin_rspJoin_rspBufferOutput_ready),
    .io_pop_payload_error(IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_error),
    .io_pop_payload_inst(IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_inst),
    .io_flush(_zz_189_),
    .io_occupancy(IBusSimplePlugin_rspJoin_rspBuffer_c_io_occupancy),
    .clk(clk),
    .reset(reset) 
  );
  always @(*) begin
    case(_zz_281_)
      2'b00 : begin
        _zz_192_ = CsrPlugin_jumpInterface_payload;
      end
      2'b01 : begin
        _zz_192_ = DBusSimplePlugin_redoBranch_payload;
      end
      2'b10 : begin
        _zz_192_ = BranchPlugin_jumpInterface_payload;
      end
      default : begin
        _zz_192_ = IBusSimplePlugin_redoBranch_payload;
      end
    endcase
  end

  `ifndef SYNTHESIS
  always @(*) begin
    case(decode_ALU_BITWISE_CTRL)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : decode_ALU_BITWISE_CTRL_string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : decode_ALU_BITWISE_CTRL_string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : decode_ALU_BITWISE_CTRL_string = "AND_1";
      default : decode_ALU_BITWISE_CTRL_string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_1_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_1__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_1__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_1__string = "AND_1";
      default : _zz_1__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_2_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_2__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_2__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_2__string = "AND_1";
      default : _zz_2__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_3_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_3__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_3__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_3__string = "AND_1";
      default : _zz_3__string = "?????";
    endcase
  end
  always @(*) begin
    case(decode_SRC1_CTRL)
      `Src1CtrlEnum_defaultEncoding_RS : decode_SRC1_CTRL_string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : decode_SRC1_CTRL_string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : decode_SRC1_CTRL_string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : decode_SRC1_CTRL_string = "URS1        ";
      default : decode_SRC1_CTRL_string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_4_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_4__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_4__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_4__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_4__string = "URS1        ";
      default : _zz_4__string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_5_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_5__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_5__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_5__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_5__string = "URS1        ";
      default : _zz_5__string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_6_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_6__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_6__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_6__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_6__string = "URS1        ";
      default : _zz_6__string = "????????????";
    endcase
  end
  always @(*) begin
    case(decode_SRC2_CTRL)
      `Src2CtrlEnum_defaultEncoding_RS : decode_SRC2_CTRL_string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : decode_SRC2_CTRL_string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : decode_SRC2_CTRL_string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : decode_SRC2_CTRL_string = "PC ";
      default : decode_SRC2_CTRL_string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_7_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_7__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_7__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_7__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_7__string = "PC ";
      default : _zz_7__string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_8_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_8__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_8__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_8__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_8__string = "PC ";
      default : _zz_8__string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_9_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_9__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_9__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_9__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_9__string = "PC ";
      default : _zz_9__string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_10_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_10__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_10__string = "XRET";
      default : _zz_10__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_11_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_11__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_11__string = "XRET";
      default : _zz_11__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_12_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_12__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_12__string = "XRET";
      default : _zz_12__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_13_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_13__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_13__string = "XRET";
      default : _zz_13__string = "????";
    endcase
  end
  always @(*) begin
    case(decode_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : decode_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : decode_ENV_CTRL_string = "XRET";
      default : decode_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_14_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_14__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_14__string = "XRET";
      default : _zz_14__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_15_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_15__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_15__string = "XRET";
      default : _zz_15__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_16_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_16__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_16__string = "XRET";
      default : _zz_16__string = "????";
    endcase
  end
  always @(*) begin
    case(decode_ALU_CTRL)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : decode_ALU_CTRL_string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : decode_ALU_CTRL_string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : decode_ALU_CTRL_string = "BITWISE ";
      default : decode_ALU_CTRL_string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_17_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_17__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_17__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_17__string = "BITWISE ";
      default : _zz_17__string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_18_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_18__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_18__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_18__string = "BITWISE ";
      default : _zz_18__string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_19_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_19__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_19__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_19__string = "BITWISE ";
      default : _zz_19__string = "????????";
    endcase
  end
  always @(*) begin
    case(decode_SHIFT_CTRL)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : decode_SHIFT_CTRL_string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : decode_SHIFT_CTRL_string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : decode_SHIFT_CTRL_string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : decode_SHIFT_CTRL_string = "SRA_1    ";
      default : decode_SHIFT_CTRL_string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_20_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_20__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_20__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_20__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_20__string = "SRA_1    ";
      default : _zz_20__string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_21_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_21__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_21__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_21__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_21__string = "SRA_1    ";
      default : _zz_21__string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_22_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_22__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_22__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_22__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_22__string = "SRA_1    ";
      default : _zz_22__string = "?????????";
    endcase
  end
  always @(*) begin
    case(decode_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_INC : decode_BRANCH_CTRL_string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : decode_BRANCH_CTRL_string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : decode_BRANCH_CTRL_string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : decode_BRANCH_CTRL_string = "JALR";
      default : decode_BRANCH_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_23_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_23__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_23__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_23__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_23__string = "JALR";
      default : _zz_23__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_24_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_24__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_24__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_24__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_24__string = "JALR";
      default : _zz_24__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_25_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_25__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_25__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_25__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_25__string = "JALR";
      default : _zz_25__string = "????";
    endcase
  end
  always @(*) begin
    case(memory_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : memory_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : memory_ENV_CTRL_string = "XRET";
      default : memory_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_26_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_26__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_26__string = "XRET";
      default : _zz_26__string = "????";
    endcase
  end
  always @(*) begin
    case(execute_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : execute_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : execute_ENV_CTRL_string = "XRET";
      default : execute_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_27_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_27__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_27__string = "XRET";
      default : _zz_27__string = "????";
    endcase
  end
  always @(*) begin
    case(writeBack_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : writeBack_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : writeBack_ENV_CTRL_string = "XRET";
      default : writeBack_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_30_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_30__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_30__string = "XRET";
      default : _zz_30__string = "????";
    endcase
  end
  always @(*) begin
    case(execute_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_INC : execute_BRANCH_CTRL_string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : execute_BRANCH_CTRL_string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : execute_BRANCH_CTRL_string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : execute_BRANCH_CTRL_string = "JALR";
      default : execute_BRANCH_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_32_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_32__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_32__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_32__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_32__string = "JALR";
      default : _zz_32__string = "????";
    endcase
  end
  always @(*) begin
    case(execute_SHIFT_CTRL)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : execute_SHIFT_CTRL_string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : execute_SHIFT_CTRL_string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : execute_SHIFT_CTRL_string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : execute_SHIFT_CTRL_string = "SRA_1    ";
      default : execute_SHIFT_CTRL_string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_35_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_35__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_35__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_35__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_35__string = "SRA_1    ";
      default : _zz_35__string = "?????????";
    endcase
  end
  always @(*) begin
    case(execute_SRC2_CTRL)
      `Src2CtrlEnum_defaultEncoding_RS : execute_SRC2_CTRL_string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : execute_SRC2_CTRL_string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : execute_SRC2_CTRL_string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : execute_SRC2_CTRL_string = "PC ";
      default : execute_SRC2_CTRL_string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_40_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_40__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_40__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_40__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_40__string = "PC ";
      default : _zz_40__string = "???";
    endcase
  end
  always @(*) begin
    case(execute_SRC1_CTRL)
      `Src1CtrlEnum_defaultEncoding_RS : execute_SRC1_CTRL_string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : execute_SRC1_CTRL_string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : execute_SRC1_CTRL_string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : execute_SRC1_CTRL_string = "URS1        ";
      default : execute_SRC1_CTRL_string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_42_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_42__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_42__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_42__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_42__string = "URS1        ";
      default : _zz_42__string = "????????????";
    endcase
  end
  always @(*) begin
    case(execute_ALU_CTRL)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : execute_ALU_CTRL_string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : execute_ALU_CTRL_string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : execute_ALU_CTRL_string = "BITWISE ";
      default : execute_ALU_CTRL_string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_45_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_45__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_45__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_45__string = "BITWISE ";
      default : _zz_45__string = "????????";
    endcase
  end
  always @(*) begin
    case(execute_ALU_BITWISE_CTRL)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : execute_ALU_BITWISE_CTRL_string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : execute_ALU_BITWISE_CTRL_string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : execute_ALU_BITWISE_CTRL_string = "AND_1";
      default : execute_ALU_BITWISE_CTRL_string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_47_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_47__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_47__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_47__string = "AND_1";
      default : _zz_47__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_55_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_55__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_55__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_55__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_55__string = "SRA_1    ";
      default : _zz_55__string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_57_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_57__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_57__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_57__string = "AND_1";
      default : _zz_57__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_59_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_59__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_59__string = "XRET";
      default : _zz_59__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_60_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_60__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_60__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_60__string = "BITWISE ";
      default : _zz_60__string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_61_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_61__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_61__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_61__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_61__string = "PC ";
      default : _zz_61__string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_69_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_69__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_69__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_69__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_69__string = "JALR";
      default : _zz_69__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_70_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_70__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_70__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_70__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_70__string = "URS1        ";
      default : _zz_70__string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_148_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_148__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_148__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_148__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_148__string = "URS1        ";
      default : _zz_148__string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_149_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_149__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_149__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_149__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_149__string = "JALR";
      default : _zz_149__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_150_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_150__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_150__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_150__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_150__string = "PC ";
      default : _zz_150__string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_151_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_151__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_151__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_151__string = "BITWISE ";
      default : _zz_151__string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_152_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_152__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_152__string = "XRET";
      default : _zz_152__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_153_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_153__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_153__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_153__string = "AND_1";
      default : _zz_153__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_154_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_154__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_154__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_154__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_154__string = "SRA_1    ";
      default : _zz_154__string = "?????????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_INC : decode_to_execute_BRANCH_CTRL_string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : decode_to_execute_BRANCH_CTRL_string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : decode_to_execute_BRANCH_CTRL_string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : decode_to_execute_BRANCH_CTRL_string = "JALR";
      default : decode_to_execute_BRANCH_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_SHIFT_CTRL)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : decode_to_execute_SHIFT_CTRL_string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : decode_to_execute_SHIFT_CTRL_string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : decode_to_execute_SHIFT_CTRL_string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : decode_to_execute_SHIFT_CTRL_string = "SRA_1    ";
      default : decode_to_execute_SHIFT_CTRL_string = "?????????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_ALU_CTRL)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : decode_to_execute_ALU_CTRL_string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : decode_to_execute_ALU_CTRL_string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : decode_to_execute_ALU_CTRL_string = "BITWISE ";
      default : decode_to_execute_ALU_CTRL_string = "????????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : decode_to_execute_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : decode_to_execute_ENV_CTRL_string = "XRET";
      default : decode_to_execute_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(execute_to_memory_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : execute_to_memory_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : execute_to_memory_ENV_CTRL_string = "XRET";
      default : execute_to_memory_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(memory_to_writeBack_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : memory_to_writeBack_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : memory_to_writeBack_ENV_CTRL_string = "XRET";
      default : memory_to_writeBack_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_SRC2_CTRL)
      `Src2CtrlEnum_defaultEncoding_RS : decode_to_execute_SRC2_CTRL_string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : decode_to_execute_SRC2_CTRL_string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : decode_to_execute_SRC2_CTRL_string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : decode_to_execute_SRC2_CTRL_string = "PC ";
      default : decode_to_execute_SRC2_CTRL_string = "???";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_SRC1_CTRL)
      `Src1CtrlEnum_defaultEncoding_RS : decode_to_execute_SRC1_CTRL_string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : decode_to_execute_SRC1_CTRL_string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : decode_to_execute_SRC1_CTRL_string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : decode_to_execute_SRC1_CTRL_string = "URS1        ";
      default : decode_to_execute_SRC1_CTRL_string = "????????????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_ALU_BITWISE_CTRL)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : decode_to_execute_ALU_BITWISE_CTRL_string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : decode_to_execute_ALU_BITWISE_CTRL_string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : decode_to_execute_ALU_BITWISE_CTRL_string = "AND_1";
      default : decode_to_execute_ALU_BITWISE_CTRL_string = "?????";
    endcase
  end
  `endif

  assign decode_RS2 = _zz_51_;
  assign memory_MEMORY_ADDRESS_LOW = execute_to_memory_MEMORY_ADDRESS_LOW;
  assign execute_MEMORY_ADDRESS_LOW = _zz_82_;
  assign writeBack_REGFILE_WRITE_DATA = memory_to_writeBack_REGFILE_WRITE_DATA;
  assign execute_REGFILE_WRITE_DATA = _zz_46_;
  assign memory_MEMORY_READ_DATA = _zz_73_;
  assign execute_BRANCH_CALC = _zz_31_;
  assign decode_ALU_BITWISE_CTRL = _zz_1_;
  assign _zz_2_ = _zz_3_;
  assign decode_SRC1_CTRL = _zz_4_;
  assign _zz_5_ = _zz_6_;
  assign writeBack_FORMAL_PC_NEXT = memory_to_writeBack_FORMAL_PC_NEXT;
  assign memory_FORMAL_PC_NEXT = execute_to_memory_FORMAL_PC_NEXT;
  assign execute_FORMAL_PC_NEXT = decode_to_execute_FORMAL_PC_NEXT;
  assign decode_FORMAL_PC_NEXT = _zz_86_;
  assign decode_SRC2_CTRL = _zz_7_;
  assign _zz_8_ = _zz_9_;
  assign decode_RS1 = _zz_52_;
  assign decode_SRC2_FORCE_ZERO = _zz_44_;
  assign _zz_10_ = _zz_11_;
  assign _zz_12_ = _zz_13_;
  assign decode_ENV_CTRL = _zz_14_;
  assign _zz_15_ = _zz_16_;
  assign decode_IS_CSR = _zz_54_;
  assign decode_ALU_CTRL = _zz_17_;
  assign _zz_18_ = _zz_19_;
  assign execute_BRANCH_DO = _zz_33_;
  assign decode_SHIFT_CTRL = _zz_20_;
  assign _zz_21_ = _zz_22_;
  assign decode_SRC_LESS_UNSIGNED = _zz_64_;
  assign execute_BYPASSABLE_MEMORY_STAGE = decode_to_execute_BYPASSABLE_MEMORY_STAGE;
  assign decode_BYPASSABLE_MEMORY_STAGE = _zz_58_;
  assign decode_BYPASSABLE_EXECUTE_STAGE = _zz_63_;
  assign decode_CSR_READ_OPCODE = _zz_28_;
  assign decode_MEMORY_STORE = _zz_62_;
  assign decode_BRANCH_CTRL = _zz_23_;
  assign _zz_24_ = _zz_25_;
  assign decode_CSR_WRITE_OPCODE = _zz_29_;
  assign execute_CSR_READ_OPCODE = decode_to_execute_CSR_READ_OPCODE;
  assign execute_CSR_WRITE_OPCODE = decode_to_execute_CSR_WRITE_OPCODE;
  assign execute_IS_CSR = decode_to_execute_IS_CSR;
  assign memory_ENV_CTRL = _zz_26_;
  assign execute_ENV_CTRL = _zz_27_;
  assign writeBack_ENV_CTRL = _zz_30_;
  assign memory_BRANCH_CALC = execute_to_memory_BRANCH_CALC;
  assign memory_BRANCH_DO = execute_to_memory_BRANCH_DO;
  assign execute_PC = decode_to_execute_PC;
  assign execute_RS1 = decode_to_execute_RS1;
  assign execute_BRANCH_CTRL = _zz_32_;
  assign decode_RS2_USE = _zz_56_;
  assign decode_RS1_USE = _zz_67_;
  assign execute_REGFILE_WRITE_VALID = decode_to_execute_REGFILE_WRITE_VALID;
  assign execute_BYPASSABLE_EXECUTE_STAGE = decode_to_execute_BYPASSABLE_EXECUTE_STAGE;
  assign memory_REGFILE_WRITE_VALID = execute_to_memory_REGFILE_WRITE_VALID;
  assign memory_INSTRUCTION = execute_to_memory_INSTRUCTION;
  assign memory_BYPASSABLE_MEMORY_STAGE = execute_to_memory_BYPASSABLE_MEMORY_STAGE;
  assign writeBack_REGFILE_WRITE_VALID = memory_to_writeBack_REGFILE_WRITE_VALID;
  always @ (*) begin
    _zz_34_ = execute_REGFILE_WRITE_DATA;
    if(_zz_193_)begin
      _zz_34_ = _zz_163_;
    end
    if(_zz_194_)begin
      _zz_34_ = execute_CsrPlugin_readData;
    end
  end

  assign execute_SHIFT_CTRL = _zz_35_;
  assign execute_SRC_LESS_UNSIGNED = decode_to_execute_SRC_LESS_UNSIGNED;
  assign execute_SRC2_FORCE_ZERO = decode_to_execute_SRC2_FORCE_ZERO;
  assign execute_SRC_USE_SUB_LESS = decode_to_execute_SRC_USE_SUB_LESS;
  assign _zz_39_ = execute_PC;
  assign execute_SRC2_CTRL = _zz_40_;
  assign execute_IS_RVC = decode_to_execute_IS_RVC;
  assign execute_SRC1_CTRL = _zz_42_;
  assign decode_SRC_USE_SUB_LESS = _zz_66_;
  assign decode_SRC_ADD_ZERO = _zz_65_;
  assign execute_SRC_ADD_SUB = _zz_38_;
  assign execute_SRC_LESS = _zz_36_;
  assign execute_ALU_CTRL = _zz_45_;
  assign execute_SRC2 = _zz_41_;
  assign execute_SRC1 = _zz_43_;
  assign execute_ALU_BITWISE_CTRL = _zz_47_;
  assign _zz_48_ = writeBack_INSTRUCTION;
  assign _zz_49_ = writeBack_REGFILE_WRITE_VALID;
  always @ (*) begin
    _zz_50_ = 1'b0;
    if(lastStageRegFileWrite_valid)begin
      _zz_50_ = 1'b1;
    end
  end

  assign decode_INSTRUCTION_ANTICIPATED = _zz_90_;
  always @ (*) begin
    decode_REGFILE_WRITE_VALID = _zz_68_;
    if((decode_INSTRUCTION[11 : 7] == (5'b00000)))begin
      decode_REGFILE_WRITE_VALID = 1'b0;
    end
  end

  assign decode_LEGAL_INSTRUCTION = _zz_71_;
  assign decode_INSTRUCTION_READY = 1'b1;
  assign writeBack_MEMORY_STORE = memory_to_writeBack_MEMORY_STORE;
  always @ (*) begin
    _zz_72_ = writeBack_REGFILE_WRITE_DATA;
    if((writeBack_arbitration_isValid && writeBack_MEMORY_ENABLE))begin
      _zz_72_ = writeBack_DBusSimplePlugin_rspFormated;
    end
  end

  assign writeBack_MEMORY_ENABLE = memory_to_writeBack_MEMORY_ENABLE;
  assign writeBack_MEMORY_ADDRESS_LOW = memory_to_writeBack_MEMORY_ADDRESS_LOW;
  assign writeBack_MEMORY_READ_DATA = memory_to_writeBack_MEMORY_READ_DATA;
  assign memory_MMU_FAULT = execute_to_memory_MMU_FAULT;
  assign memory_MMU_RSP_physicalAddress = execute_to_memory_MMU_RSP_physicalAddress;
  assign memory_MMU_RSP_isIoAccess = execute_to_memory_MMU_RSP_isIoAccess;
  assign memory_MMU_RSP_allowRead = execute_to_memory_MMU_RSP_allowRead;
  assign memory_MMU_RSP_allowWrite = execute_to_memory_MMU_RSP_allowWrite;
  assign memory_MMU_RSP_allowExecute = execute_to_memory_MMU_RSP_allowExecute;
  assign memory_MMU_RSP_exception = execute_to_memory_MMU_RSP_exception;
  assign memory_MMU_RSP_refilling = execute_to_memory_MMU_RSP_refilling;
  assign memory_PC = execute_to_memory_PC;
  assign memory_ALIGNEMENT_FAULT = execute_to_memory_ALIGNEMENT_FAULT;
  assign memory_REGFILE_WRITE_DATA = execute_to_memory_REGFILE_WRITE_DATA;
  assign memory_MEMORY_STORE = execute_to_memory_MEMORY_STORE;
  assign memory_MEMORY_ENABLE = execute_to_memory_MEMORY_ENABLE;
  assign execute_MMU_FAULT = _zz_81_;
  assign execute_MMU_RSP_physicalAddress = _zz_74_;
  assign execute_MMU_RSP_isIoAccess = _zz_75_;
  assign execute_MMU_RSP_allowRead = _zz_76_;
  assign execute_MMU_RSP_allowWrite = _zz_77_;
  assign execute_MMU_RSP_allowExecute = _zz_78_;
  assign execute_MMU_RSP_exception = _zz_79_;
  assign execute_MMU_RSP_refilling = _zz_80_;
  assign execute_SRC_ADD = _zz_37_;
  assign execute_RS2 = decode_to_execute_RS2;
  assign execute_INSTRUCTION = decode_to_execute_INSTRUCTION;
  assign execute_MEMORY_STORE = decode_to_execute_MEMORY_STORE;
  assign execute_MEMORY_ENABLE = decode_to_execute_MEMORY_ENABLE;
  assign execute_ALIGNEMENT_FAULT = _zz_83_;
  assign decode_MEMORY_ENABLE = _zz_53_;
  always @ (*) begin
    _zz_84_ = memory_FORMAL_PC_NEXT;
    if(DBusSimplePlugin_redoBranch_valid)begin
      _zz_84_ = DBusSimplePlugin_redoBranch_payload;
    end
    if(BranchPlugin_jumpInterface_valid)begin
      _zz_84_ = BranchPlugin_jumpInterface_payload;
    end
  end

  always @ (*) begin
    _zz_85_ = decode_FORMAL_PC_NEXT;
    if(IBusSimplePlugin_redoBranch_valid)begin
      _zz_85_ = IBusSimplePlugin_redoBranch_payload;
    end
  end

  assign decode_PC = _zz_89_;
  assign decode_INSTRUCTION = _zz_88_;
  assign decode_IS_RVC = _zz_87_;
  assign writeBack_PC = memory_to_writeBack_PC;
  assign writeBack_INSTRUCTION = memory_to_writeBack_INSTRUCTION;
  always @ (*) begin
    decode_arbitration_haltItself = 1'b0;
    if(((DBusSimplePlugin_mmuBus_busy && decode_arbitration_isValid) && decode_MEMORY_ENABLE))begin
      decode_arbitration_haltItself = 1'b1;
    end
  end

  always @ (*) begin
    decode_arbitration_haltByOther = 1'b0;
    if((decode_arbitration_isValid && (_zz_164_ || _zz_165_)))begin
      decode_arbitration_haltByOther = 1'b1;
    end
    if((CsrPlugin_interrupt_valid && CsrPlugin_allowInterrupts))begin
      decode_arbitration_haltByOther = decode_arbitration_isValid;
    end
    if(({(writeBack_arbitration_isValid && (writeBack_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET)),{(memory_arbitration_isValid && (memory_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET)),(execute_arbitration_isValid && (execute_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET))}} != (3'b000)))begin
      decode_arbitration_haltByOther = 1'b1;
    end
  end

  always @ (*) begin
    decode_arbitration_removeIt = 1'b0;
    if(_zz_195_)begin
      decode_arbitration_removeIt = 1'b1;
    end
    if(decode_arbitration_isFlushed)begin
      decode_arbitration_removeIt = 1'b1;
    end
  end

  always @ (*) begin
    decode_arbitration_flushAll = 1'b0;
    if(IBusSimplePlugin_redoBranch_valid)begin
      decode_arbitration_flushAll = 1'b1;
    end
  end

  always @ (*) begin
    execute_arbitration_haltItself = 1'b0;
    if(((((execute_arbitration_isValid && execute_MEMORY_ENABLE) && (! dBus_cmd_ready)) && (! execute_DBusSimplePlugin_skipCmd)) && (! _zz_136_)))begin
      execute_arbitration_haltItself = 1'b1;
    end
    if(_zz_193_)begin
      if(_zz_196_)begin
        if(! execute_LightShifterPlugin_done) begin
          execute_arbitration_haltItself = 1'b1;
        end
      end
    end
    if(_zz_194_)begin
      if(execute_CsrPlugin_blockedBySideEffects)begin
        execute_arbitration_haltItself = 1'b1;
      end
    end
  end

  assign execute_arbitration_haltByOther = 1'b0;
  always @ (*) begin
    execute_arbitration_removeIt = 1'b0;
    if(execute_arbitration_isFlushed)begin
      execute_arbitration_removeIt = 1'b1;
    end
  end

  always @ (*) begin
    execute_arbitration_flushAll = 1'b0;
    if(BranchPlugin_jumpInterface_valid)begin
      execute_arbitration_flushAll = 1'b1;
    end
    if(DBusSimplePlugin_memoryExceptionPort_valid)begin
      execute_arbitration_flushAll = 1'b1;
    end
  end

  always @ (*) begin
    memory_arbitration_haltItself = 1'b0;
    if((((memory_arbitration_isValid && memory_MEMORY_ENABLE) && (! memory_MEMORY_STORE)) && ((! dBus_rsp_ready) || 1'b0)))begin
      memory_arbitration_haltItself = 1'b1;
    end
  end

  assign memory_arbitration_haltByOther = 1'b0;
  always @ (*) begin
    memory_arbitration_removeIt = 1'b0;
    if(DBusSimplePlugin_memoryExceptionPort_valid)begin
      memory_arbitration_removeIt = 1'b1;
    end
    if(memory_arbitration_isFlushed)begin
      memory_arbitration_removeIt = 1'b1;
    end
  end

  always @ (*) begin
    memory_arbitration_flushAll = 1'b0;
    if(DBusSimplePlugin_redoBranch_valid)begin
      memory_arbitration_flushAll = 1'b1;
    end
    if(_zz_197_)begin
      memory_arbitration_flushAll = 1'b1;
    end
    if(_zz_198_)begin
      memory_arbitration_flushAll = 1'b1;
    end
  end

  assign writeBack_arbitration_haltItself = 1'b0;
  assign writeBack_arbitration_haltByOther = 1'b0;
  always @ (*) begin
    writeBack_arbitration_removeIt = 1'b0;
    if(writeBack_arbitration_isFlushed)begin
      writeBack_arbitration_removeIt = 1'b1;
    end
  end

  assign writeBack_arbitration_flushAll = 1'b0;
  assign lastStageInstruction = writeBack_INSTRUCTION;
  assign lastStagePc = writeBack_PC;
  assign lastStageIsValid = writeBack_arbitration_isValid;
  assign lastStageIsFiring = writeBack_arbitration_isFiring;
  always @ (*) begin
    IBusSimplePlugin_fetcherHalt = 1'b0;
    if(({CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_writeBack,{CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_memory,{CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_execute,CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_decode}}} != (4'b0000)))begin
      IBusSimplePlugin_fetcherHalt = 1'b1;
    end
    if(_zz_197_)begin
      IBusSimplePlugin_fetcherHalt = 1'b1;
    end
    if(_zz_198_)begin
      IBusSimplePlugin_fetcherHalt = 1'b1;
    end
  end

  assign IBusSimplePlugin_fetcherflushIt = 1'b0;
  always @ (*) begin
    IBusSimplePlugin_incomingInstruction = 1'b0;
    if(IBusSimplePlugin_iBusRsp_stages_1_input_valid)begin
      IBusSimplePlugin_incomingInstruction = 1'b1;
    end
    if((IBusSimplePlugin_decompressor_bufferValid && (IBusSimplePlugin_decompressor_bufferData[1 : 0] != (2'b11))))begin
      IBusSimplePlugin_incomingInstruction = 1'b1;
    end
    if(IBusSimplePlugin_injector_decodeInput_valid)begin
      IBusSimplePlugin_incomingInstruction = 1'b1;
    end
  end

  always @ (*) begin
    CsrPlugin_jumpInterface_valid = 1'b0;
    if(_zz_197_)begin
      CsrPlugin_jumpInterface_valid = 1'b1;
    end
    if(_zz_198_)begin
      CsrPlugin_jumpInterface_valid = 1'b1;
    end
  end

  always @ (*) begin
    CsrPlugin_jumpInterface_payload = (32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
    if(_zz_197_)begin
      CsrPlugin_jumpInterface_payload = {CsrPlugin_xtvec_base,(2'b00)};
    end
    if(_zz_198_)begin
      case(_zz_199_)
        2'b11 : begin
          CsrPlugin_jumpInterface_payload = CsrPlugin_mepc;
        end
        default : begin
        end
      endcase
    end
  end

  assign CsrPlugin_forceMachineWire = 1'b0;
  assign CsrPlugin_allowInterrupts = 1'b1;
  assign CsrPlugin_allowException = 1'b1;
  assign IBusSimplePlugin_jump_pcLoad_valid = ({CsrPlugin_jumpInterface_valid,{BranchPlugin_jumpInterface_valid,{DBusSimplePlugin_redoBranch_valid,IBusSimplePlugin_redoBranch_valid}}} != (4'b0000));
  assign _zz_91_ = {IBusSimplePlugin_redoBranch_valid,{BranchPlugin_jumpInterface_valid,{DBusSimplePlugin_redoBranch_valid,CsrPlugin_jumpInterface_valid}}};
  assign _zz_92_ = (_zz_91_ & (~ _zz_222_));
  assign _zz_93_ = _zz_92_[3];
  assign _zz_94_ = (_zz_92_[1] || _zz_93_);
  assign _zz_95_ = (_zz_92_[2] || _zz_93_);
  assign IBusSimplePlugin_jump_pcLoad_payload = _zz_192_;
  assign _zz_96_ = (! IBusSimplePlugin_fetcherHalt);
  assign IBusSimplePlugin_fetchPc_output_valid = (IBusSimplePlugin_fetchPc_preOutput_valid && _zz_96_);
  assign IBusSimplePlugin_fetchPc_preOutput_ready = (IBusSimplePlugin_fetchPc_output_ready && _zz_96_);
  assign IBusSimplePlugin_fetchPc_output_payload = IBusSimplePlugin_fetchPc_preOutput_payload;
  always @ (*) begin
    IBusSimplePlugin_fetchPc_propagatePc = 1'b0;
    if((IBusSimplePlugin_iBusRsp_stages_1_input_valid && IBusSimplePlugin_iBusRsp_stages_1_input_ready))begin
      IBusSimplePlugin_fetchPc_propagatePc = 1'b1;
    end
  end

  always @ (*) begin
    IBusSimplePlugin_fetchPc_pc = (IBusSimplePlugin_fetchPc_pcReg + _zz_224_);
    if(IBusSimplePlugin_fetchPc_inc)begin
      IBusSimplePlugin_fetchPc_pc[1] = 1'b0;
    end
    if(IBusSimplePlugin_jump_pcLoad_valid)begin
      IBusSimplePlugin_fetchPc_pc = IBusSimplePlugin_jump_pcLoad_payload;
    end
    IBusSimplePlugin_fetchPc_pc[0] = 1'b0;
  end

  always @ (*) begin
    IBusSimplePlugin_fetchPc_samplePcNext = 1'b0;
    if(IBusSimplePlugin_fetchPc_propagatePc)begin
      IBusSimplePlugin_fetchPc_samplePcNext = 1'b1;
    end
    if(IBusSimplePlugin_jump_pcLoad_valid)begin
      IBusSimplePlugin_fetchPc_samplePcNext = 1'b1;
    end
    if(_zz_200_)begin
      IBusSimplePlugin_fetchPc_samplePcNext = 1'b1;
    end
  end

  assign IBusSimplePlugin_fetchPc_preOutput_valid = _zz_97_;
  assign IBusSimplePlugin_fetchPc_preOutput_payload = IBusSimplePlugin_fetchPc_pc;
  assign IBusSimplePlugin_decodePc_pcPlus = (IBusSimplePlugin_decodePc_pcReg + _zz_226_);
  assign IBusSimplePlugin_decodePc_injectedDecode = 1'b0;
  always @ (*) begin
    IBusSimplePlugin_iBusRsp_stages_0_input_valid = IBusSimplePlugin_fetchPc_output_valid;
    if(IBusSimplePlugin_mmuBus_busy)begin
      IBusSimplePlugin_iBusRsp_stages_0_input_valid = 1'b0;
    end
  end

  assign IBusSimplePlugin_fetchPc_output_ready = IBusSimplePlugin_iBusRsp_stages_0_input_ready;
  assign IBusSimplePlugin_iBusRsp_stages_0_input_payload = IBusSimplePlugin_fetchPc_output_payload;
  assign IBusSimplePlugin_iBusRsp_stages_0_inputSample = 1'b1;
  always @ (*) begin
    IBusSimplePlugin_iBusRsp_stages_0_halt = 1'b0;
    if((IBusSimplePlugin_iBusRsp_stages_0_input_valid && ((! IBusSimplePlugin_cmd_valid) || (! IBusSimplePlugin_cmd_ready))))begin
      IBusSimplePlugin_iBusRsp_stages_0_halt = 1'b1;
    end
    if(_zz_201_)begin
      IBusSimplePlugin_iBusRsp_stages_0_halt = 1'b0;
    end
  end

  assign _zz_98_ = (! IBusSimplePlugin_iBusRsp_stages_0_halt);
  always @ (*) begin
    IBusSimplePlugin_iBusRsp_stages_0_input_ready = (IBusSimplePlugin_iBusRsp_stages_0_output_ready && _zz_98_);
    if(IBusSimplePlugin_mmuBus_busy)begin
      IBusSimplePlugin_iBusRsp_stages_0_input_ready = 1'b0;
    end
  end

  assign IBusSimplePlugin_iBusRsp_stages_0_output_valid = (IBusSimplePlugin_iBusRsp_stages_0_input_valid && _zz_98_);
  assign IBusSimplePlugin_iBusRsp_stages_0_output_payload = IBusSimplePlugin_iBusRsp_stages_0_input_payload;
  assign IBusSimplePlugin_iBusRsp_stages_1_halt = 1'b0;
  assign _zz_99_ = (! IBusSimplePlugin_iBusRsp_stages_1_halt);
  assign IBusSimplePlugin_iBusRsp_stages_1_input_ready = (IBusSimplePlugin_iBusRsp_stages_1_output_ready && _zz_99_);
  assign IBusSimplePlugin_iBusRsp_stages_1_output_valid = (IBusSimplePlugin_iBusRsp_stages_1_input_valid && _zz_99_);
  assign IBusSimplePlugin_iBusRsp_stages_1_output_payload = IBusSimplePlugin_iBusRsp_stages_1_input_payload;
  assign IBusSimplePlugin_iBusRsp_stages_0_output_ready = _zz_100_;
  assign _zz_100_ = ((1'b0 && (! _zz_101_)) || IBusSimplePlugin_iBusRsp_stages_1_input_ready);
  assign _zz_101_ = _zz_102_;
  assign IBusSimplePlugin_iBusRsp_stages_1_input_valid = _zz_101_;
  assign IBusSimplePlugin_iBusRsp_stages_1_input_payload = IBusSimplePlugin_fetchPc_pcReg;
  always @ (*) begin
    IBusSimplePlugin_iBusRsp_readyForError = 1'b1;
    if((IBusSimplePlugin_decompressor_bufferValid && IBusSimplePlugin_decompressor_isRvc))begin
      IBusSimplePlugin_iBusRsp_readyForError = 1'b0;
    end
    if(IBusSimplePlugin_injector_decodeInput_valid)begin
      IBusSimplePlugin_iBusRsp_readyForError = 1'b0;
    end
  end

  assign IBusSimplePlugin_decompressor_raw = (IBusSimplePlugin_decompressor_bufferValid ? {IBusSimplePlugin_iBusRsp_output_payload_rsp_inst[15 : 0],IBusSimplePlugin_decompressor_bufferData} : {IBusSimplePlugin_iBusRsp_output_payload_rsp_inst[31 : 16],(IBusSimplePlugin_iBusRsp_output_payload_pc[1] ? IBusSimplePlugin_iBusRsp_output_payload_rsp_inst[31 : 16] : IBusSimplePlugin_iBusRsp_output_payload_rsp_inst[15 : 0])});
  assign IBusSimplePlugin_decompressor_isRvc = (IBusSimplePlugin_decompressor_raw[1 : 0] != (2'b11));
  assign _zz_103_ = IBusSimplePlugin_decompressor_raw[15 : 0];
  always @ (*) begin
    IBusSimplePlugin_decompressor_decompressed = (32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
    case(_zz_217_)
      5'b00000 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{{{{{(2'b00),_zz_103_[10 : 7]},_zz_103_[12 : 11]},_zz_103_[5]},_zz_103_[6]},(2'b00)},(5'b00010)},(3'b000)},_zz_105_},(7'b0010011)};
      end
      5'b00010 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{_zz_106_,_zz_104_},(3'b010)},_zz_105_},(7'b0000011)};
      end
      5'b00110 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{_zz_106_[11 : 5],_zz_105_},_zz_104_},(3'b010)},_zz_106_[4 : 0]},(7'b0100011)};
      end
      5'b01000 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{_zz_108_,_zz_103_[11 : 7]},(3'b000)},_zz_103_[11 : 7]},(7'b0010011)};
      end
      5'b01001 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{_zz_111_[20],_zz_111_[10 : 1]},_zz_111_[11]},_zz_111_[19 : 12]},_zz_123_},(7'b1101111)};
      end
      5'b01010 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{_zz_108_,(5'b00000)},(3'b000)},_zz_103_[11 : 7]},(7'b0010011)};
      end
      5'b01011 : begin
        IBusSimplePlugin_decompressor_decompressed = ((_zz_103_[11 : 7] == (5'b00010)) ? {{{{{{{{{_zz_115_,_zz_103_[4 : 3]},_zz_103_[5]},_zz_103_[2]},_zz_103_[6]},(4'b0000)},_zz_103_[11 : 7]},(3'b000)},_zz_103_[11 : 7]},(7'b0010011)} : {{_zz_227_[31 : 12],_zz_103_[11 : 7]},(7'b0110111)});
      end
      5'b01100 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{((_zz_103_[11 : 10] == (2'b10)) ? _zz_129_ : {{(1'b0),(_zz_282_ || _zz_283_)},(5'b00000)}),(((! _zz_103_[11]) || _zz_125_) ? _zz_103_[6 : 2] : _zz_105_)},_zz_104_},_zz_127_},_zz_104_},(_zz_125_ ? (7'b0010011) : (7'b0110011))};
      end
      5'b01101 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{_zz_118_[20],_zz_118_[10 : 1]},_zz_118_[11]},_zz_118_[19 : 12]},_zz_122_},(7'b1101111)};
      end
      5'b01110 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{{{_zz_121_[12],_zz_121_[10 : 5]},_zz_122_},_zz_104_},(3'b000)},_zz_121_[4 : 1]},_zz_121_[11]},(7'b1100011)};
      end
      5'b01111 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{{{_zz_121_[12],_zz_121_[10 : 5]},_zz_122_},_zz_104_},(3'b001)},_zz_121_[4 : 1]},_zz_121_[11]},(7'b1100011)};
      end
      5'b10000 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{(7'b0000000),_zz_103_[6 : 2]},_zz_103_[11 : 7]},(3'b001)},_zz_103_[11 : 7]},(7'b0010011)};
      end
      5'b10010 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{{{{(4'b0000),_zz_103_[3 : 2]},_zz_103_[12]},_zz_103_[6 : 4]},(2'b00)},_zz_124_},(3'b010)},_zz_103_[11 : 7]},(7'b0000011)};
      end
      5'b10100 : begin
        IBusSimplePlugin_decompressor_decompressed = ((_zz_103_[12 : 2] == (11'b10000000000)) ? (32'b00000000000100000000000001110011) : ((_zz_103_[6 : 2] == (5'b00000)) ? {{{{(12'b000000000000),_zz_103_[11 : 7]},(3'b000)},(_zz_103_[12] ? _zz_123_ : _zz_122_)},(7'b1100111)} : {{{{{_zz_284_,_zz_285_},(_zz_286_ ? _zz_287_ : _zz_122_)},(3'b000)},_zz_103_[11 : 7]},(7'b0110011)}));
      end
      5'b10110 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{_zz_228_[11 : 5],_zz_103_[6 : 2]},_zz_124_},(3'b010)},_zz_229_[4 : 0]},(7'b0100011)};
      end
      default : begin
      end
    endcase
  end

  assign _zz_104_ = {(2'b01),_zz_103_[9 : 7]};
  assign _zz_105_ = {(2'b01),_zz_103_[4 : 2]};
  assign _zz_106_ = {{{{(5'b00000),_zz_103_[5]},_zz_103_[12 : 10]},_zz_103_[6]},(2'b00)};
  assign _zz_107_ = _zz_103_[12];
  always @ (*) begin
    _zz_108_[11] = _zz_107_;
    _zz_108_[10] = _zz_107_;
    _zz_108_[9] = _zz_107_;
    _zz_108_[8] = _zz_107_;
    _zz_108_[7] = _zz_107_;
    _zz_108_[6] = _zz_107_;
    _zz_108_[5] = _zz_107_;
    _zz_108_[4 : 0] = _zz_103_[6 : 2];
  end

  assign _zz_109_ = _zz_103_[12];
  always @ (*) begin
    _zz_110_[9] = _zz_109_;
    _zz_110_[8] = _zz_109_;
    _zz_110_[7] = _zz_109_;
    _zz_110_[6] = _zz_109_;
    _zz_110_[5] = _zz_109_;
    _zz_110_[4] = _zz_109_;
    _zz_110_[3] = _zz_109_;
    _zz_110_[2] = _zz_109_;
    _zz_110_[1] = _zz_109_;
    _zz_110_[0] = _zz_109_;
  end

  assign _zz_111_ = {{{{{{{{_zz_110_,_zz_103_[8]},_zz_103_[10 : 9]},_zz_103_[6]},_zz_103_[7]},_zz_103_[2]},_zz_103_[11]},_zz_103_[5 : 3]},(1'b0)};
  assign _zz_112_ = _zz_103_[12];
  always @ (*) begin
    _zz_113_[14] = _zz_112_;
    _zz_113_[13] = _zz_112_;
    _zz_113_[12] = _zz_112_;
    _zz_113_[11] = _zz_112_;
    _zz_113_[10] = _zz_112_;
    _zz_113_[9] = _zz_112_;
    _zz_113_[8] = _zz_112_;
    _zz_113_[7] = _zz_112_;
    _zz_113_[6] = _zz_112_;
    _zz_113_[5] = _zz_112_;
    _zz_113_[4] = _zz_112_;
    _zz_113_[3] = _zz_112_;
    _zz_113_[2] = _zz_112_;
    _zz_113_[1] = _zz_112_;
    _zz_113_[0] = _zz_112_;
  end

  assign _zz_114_ = _zz_103_[12];
  always @ (*) begin
    _zz_115_[2] = _zz_114_;
    _zz_115_[1] = _zz_114_;
    _zz_115_[0] = _zz_114_;
  end

  assign _zz_116_ = _zz_103_[12];
  always @ (*) begin
    _zz_117_[9] = _zz_116_;
    _zz_117_[8] = _zz_116_;
    _zz_117_[7] = _zz_116_;
    _zz_117_[6] = _zz_116_;
    _zz_117_[5] = _zz_116_;
    _zz_117_[4] = _zz_116_;
    _zz_117_[3] = _zz_116_;
    _zz_117_[2] = _zz_116_;
    _zz_117_[1] = _zz_116_;
    _zz_117_[0] = _zz_116_;
  end

  assign _zz_118_ = {{{{{{{{_zz_117_,_zz_103_[8]},_zz_103_[10 : 9]},_zz_103_[6]},_zz_103_[7]},_zz_103_[2]},_zz_103_[11]},_zz_103_[5 : 3]},(1'b0)};
  assign _zz_119_ = _zz_103_[12];
  always @ (*) begin
    _zz_120_[4] = _zz_119_;
    _zz_120_[3] = _zz_119_;
    _zz_120_[2] = _zz_119_;
    _zz_120_[1] = _zz_119_;
    _zz_120_[0] = _zz_119_;
  end

  assign _zz_121_ = {{{{{_zz_120_,_zz_103_[6 : 5]},_zz_103_[2]},_zz_103_[11 : 10]},_zz_103_[4 : 3]},(1'b0)};
  assign _zz_122_ = (5'b00000);
  assign _zz_123_ = (5'b00001);
  assign _zz_124_ = (5'b00010);
  assign _zz_125_ = (_zz_103_[11 : 10] != (2'b11));
  always @ (*) begin
    case(_zz_218_)
      2'b00 : begin
        _zz_126_ = (3'b000);
      end
      2'b01 : begin
        _zz_126_ = (3'b100);
      end
      2'b10 : begin
        _zz_126_ = (3'b110);
      end
      default : begin
        _zz_126_ = (3'b111);
      end
    endcase
  end

  always @ (*) begin
    case(_zz_219_)
      2'b00 : begin
        _zz_127_ = (3'b101);
      end
      2'b01 : begin
        _zz_127_ = (3'b101);
      end
      2'b10 : begin
        _zz_127_ = (3'b111);
      end
      default : begin
        _zz_127_ = _zz_126_;
      end
    endcase
  end

  assign _zz_128_ = _zz_103_[12];
  always @ (*) begin
    _zz_129_[6] = _zz_128_;
    _zz_129_[5] = _zz_128_;
    _zz_129_[4] = _zz_128_;
    _zz_129_[3] = _zz_128_;
    _zz_129_[2] = _zz_128_;
    _zz_129_[1] = _zz_128_;
    _zz_129_[0] = _zz_128_;
  end

  assign IBusSimplePlugin_decompressor_inputBeforeStage_valid = (IBusSimplePlugin_decompressor_isRvc ? (IBusSimplePlugin_decompressor_bufferValid || IBusSimplePlugin_iBusRsp_output_valid) : (IBusSimplePlugin_iBusRsp_output_valid && (IBusSimplePlugin_decompressor_bufferValid || (! IBusSimplePlugin_iBusRsp_output_payload_pc[1]))));
  assign IBusSimplePlugin_decompressor_inputBeforeStage_payload_pc = IBusSimplePlugin_iBusRsp_output_payload_pc;
  assign IBusSimplePlugin_decompressor_inputBeforeStage_payload_isRvc = IBusSimplePlugin_decompressor_isRvc;
  assign IBusSimplePlugin_decompressor_inputBeforeStage_payload_rsp_inst = (IBusSimplePlugin_decompressor_isRvc ? IBusSimplePlugin_decompressor_decompressed : IBusSimplePlugin_decompressor_raw);
  assign IBusSimplePlugin_iBusRsp_output_ready = ((! IBusSimplePlugin_decompressor_inputBeforeStage_valid) || (! (((! IBusSimplePlugin_decompressor_inputBeforeStage_ready) || ((IBusSimplePlugin_decompressor_isRvc && (! IBusSimplePlugin_iBusRsp_output_payload_pc[1])) && (IBusSimplePlugin_iBusRsp_output_payload_rsp_inst[17 : 16] != (2'b11)))) || (((! IBusSimplePlugin_decompressor_isRvc) && IBusSimplePlugin_decompressor_bufferValid) && (IBusSimplePlugin_iBusRsp_output_payload_rsp_inst[17 : 16] != (2'b11))))));
  assign IBusSimplePlugin_decompressor_inputBeforeStage_ready = ((1'b0 && (! IBusSimplePlugin_injector_decodeInput_valid)) || IBusSimplePlugin_injector_decodeInput_ready);
  assign IBusSimplePlugin_injector_decodeInput_valid = _zz_130_;
  assign IBusSimplePlugin_injector_decodeInput_payload_pc = _zz_131_;
  assign IBusSimplePlugin_injector_decodeInput_payload_rsp_error = _zz_132_;
  assign IBusSimplePlugin_injector_decodeInput_payload_rsp_inst = _zz_133_;
  assign IBusSimplePlugin_injector_decodeInput_payload_isRvc = _zz_134_;
  assign _zz_90_ = (decode_arbitration_isStuck ? decode_INSTRUCTION : IBusSimplePlugin_decompressor_inputBeforeStage_payload_rsp_inst);
  assign IBusSimplePlugin_pcValids_0 = IBusSimplePlugin_injector_nextPcCalc_valids_0;
  assign IBusSimplePlugin_pcValids_1 = IBusSimplePlugin_injector_nextPcCalc_valids_1;
  assign IBusSimplePlugin_pcValids_2 = IBusSimplePlugin_injector_nextPcCalc_valids_2;
  assign IBusSimplePlugin_pcValids_3 = IBusSimplePlugin_injector_nextPcCalc_valids_3;
  assign IBusSimplePlugin_injector_decodeInput_ready = (! decode_arbitration_isStuck);
  assign decode_arbitration_isValid = (IBusSimplePlugin_injector_decodeInput_valid && (! IBusSimplePlugin_injector_decodeRemoved));
  assign _zz_89_ = IBusSimplePlugin_decodePc_pcReg;
  assign _zz_88_ = IBusSimplePlugin_injector_decodeInput_payload_rsp_inst;
  assign _zz_87_ = IBusSimplePlugin_injector_decodeInput_payload_isRvc;
  assign _zz_86_ = (decode_PC + _zz_231_);
  assign iBus_cmd_valid = IBusSimplePlugin_cmd_valid;
  assign IBusSimplePlugin_cmd_ready = iBus_cmd_ready;
  assign iBus_cmd_payload_pc = IBusSimplePlugin_cmd_payload_pc;
  assign IBusSimplePlugin_pendingCmdNext = (_zz_232_ - _zz_236_);
  always @ (*) begin
    IBusSimplePlugin_cmd_valid = ((IBusSimplePlugin_iBusRsp_stages_0_input_valid && IBusSimplePlugin_iBusRsp_stages_0_output_ready) && (IBusSimplePlugin_pendingCmd != (3'b111)));
    if(_zz_201_)begin
      IBusSimplePlugin_cmd_valid = 1'b0;
    end
  end

  assign IBusSimplePlugin_mmuBus_cmd_isValid = IBusSimplePlugin_iBusRsp_stages_0_input_valid;
  assign IBusSimplePlugin_mmuBus_cmd_virtualAddress = IBusSimplePlugin_iBusRsp_stages_0_input_payload;
  assign IBusSimplePlugin_mmuBus_cmd_bypassTranslation = 1'b0;
  assign IBusSimplePlugin_mmuBus_end = ((IBusSimplePlugin_iBusRsp_stages_0_output_valid && IBusSimplePlugin_iBusRsp_stages_0_output_ready) || (IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt));
  assign IBusSimplePlugin_cmd_payload_pc = {IBusSimplePlugin_mmuBus_rsp_physicalAddress[31 : 2],(2'b00)};
  assign iBus_rsp_takeWhen_valid = (iBus_rsp_valid && (! (IBusSimplePlugin_rspJoin_discardCounter != (3'b000))));
  assign iBus_rsp_takeWhen_payload_error = iBus_rsp_payload_error;
  assign iBus_rsp_takeWhen_payload_inst = iBus_rsp_payload_inst;
  assign _zz_189_ = (IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt);
  assign IBusSimplePlugin_rspJoin_rspBufferOutput_valid = IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_valid;
  assign IBusSimplePlugin_rspJoin_rspBufferOutput_payload_error = IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_error;
  assign IBusSimplePlugin_rspJoin_rspBufferOutput_payload_inst = IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_inst;
  assign IBusSimplePlugin_rspJoin_fetchRsp_pc = IBusSimplePlugin_iBusRsp_stages_1_output_payload;
  always @ (*) begin
    IBusSimplePlugin_rspJoin_fetchRsp_rsp_error = IBusSimplePlugin_rspJoin_rspBufferOutput_payload_error;
    if((! IBusSimplePlugin_rspJoin_rspBufferOutput_valid))begin
      IBusSimplePlugin_rspJoin_fetchRsp_rsp_error = 1'b0;
    end
  end

  assign IBusSimplePlugin_rspJoin_fetchRsp_rsp_inst = IBusSimplePlugin_rspJoin_rspBufferOutput_payload_inst;
  always @ (*) begin
    IBusSimplePlugin_rspJoin_exceptionDetected = 1'b0;
    if(_zz_202_)begin
      IBusSimplePlugin_rspJoin_exceptionDetected = 1'b1;
    end
  end

  always @ (*) begin
    IBusSimplePlugin_rspJoin_redoRequired = 1'b0;
    if((IBusSimplePlugin_iBusRsp_stages_1_input_valid && IBusSimplePlugin_mmu_joinCtx_refilling))begin
      IBusSimplePlugin_rspJoin_redoRequired = 1'b1;
    end
  end

  assign IBusSimplePlugin_rspJoin_join_valid = (IBusSimplePlugin_iBusRsp_stages_1_output_valid && IBusSimplePlugin_rspJoin_rspBufferOutput_valid);
  assign IBusSimplePlugin_rspJoin_join_payload_pc = IBusSimplePlugin_rspJoin_fetchRsp_pc;
  assign IBusSimplePlugin_rspJoin_join_payload_rsp_error = IBusSimplePlugin_rspJoin_fetchRsp_rsp_error;
  assign IBusSimplePlugin_rspJoin_join_payload_rsp_inst = IBusSimplePlugin_rspJoin_fetchRsp_rsp_inst;
  assign IBusSimplePlugin_rspJoin_join_payload_isRvc = IBusSimplePlugin_rspJoin_fetchRsp_isRvc;
  assign IBusSimplePlugin_iBusRsp_stages_1_output_ready = (IBusSimplePlugin_iBusRsp_stages_1_output_valid ? (IBusSimplePlugin_rspJoin_join_valid && IBusSimplePlugin_rspJoin_join_ready) : IBusSimplePlugin_rspJoin_join_ready);
  assign IBusSimplePlugin_rspJoin_rspBufferOutput_ready = (IBusSimplePlugin_rspJoin_join_valid && IBusSimplePlugin_rspJoin_join_ready);
  assign _zz_135_ = (! (IBusSimplePlugin_rspJoin_exceptionDetected || IBusSimplePlugin_rspJoin_redoRequired));
  assign IBusSimplePlugin_rspJoin_join_ready = (IBusSimplePlugin_iBusRsp_output_ready && _zz_135_);
  assign IBusSimplePlugin_iBusRsp_output_valid = (IBusSimplePlugin_rspJoin_join_valid && _zz_135_);
  assign IBusSimplePlugin_iBusRsp_output_payload_pc = IBusSimplePlugin_rspJoin_join_payload_pc;
  assign IBusSimplePlugin_iBusRsp_output_payload_rsp_error = IBusSimplePlugin_rspJoin_join_payload_rsp_error;
  assign IBusSimplePlugin_iBusRsp_output_payload_rsp_inst = IBusSimplePlugin_rspJoin_join_payload_rsp_inst;
  assign IBusSimplePlugin_iBusRsp_output_payload_isRvc = IBusSimplePlugin_rspJoin_join_payload_isRvc;
  assign IBusSimplePlugin_redoBranch_valid = (IBusSimplePlugin_rspJoin_redoRequired && IBusSimplePlugin_iBusRsp_readyForError);
  assign IBusSimplePlugin_redoBranch_payload = decode_PC;
  always @ (*) begin
    IBusSimplePlugin_decodeExceptionPort_payload_code = (4'bxxxx);
    if(_zz_202_)begin
      IBusSimplePlugin_decodeExceptionPort_payload_code = (4'b1100);
    end
  end

  assign IBusSimplePlugin_decodeExceptionPort_payload_badAddr = {IBusSimplePlugin_rspJoin_join_payload_pc[31 : 2],(2'b00)};
  assign IBusSimplePlugin_decodeExceptionPort_valid = ((IBusSimplePlugin_rspJoin_exceptionDetected && IBusSimplePlugin_iBusRsp_readyForError) && (! IBusSimplePlugin_fetcherHalt));
  assign _zz_136_ = 1'b0;
  assign _zz_83_ = (((dBus_cmd_payload_size == (2'b10)) && (dBus_cmd_payload_address[1 : 0] != (2'b00))) || ((dBus_cmd_payload_size == (2'b01)) && (dBus_cmd_payload_address[0 : 0] != (1'b0))));
  always @ (*) begin
    execute_DBusSimplePlugin_skipCmd = 1'b0;
    if(execute_ALIGNEMENT_FAULT)begin
      execute_DBusSimplePlugin_skipCmd = 1'b1;
    end
    if((execute_MMU_FAULT || execute_MMU_RSP_refilling))begin
      execute_DBusSimplePlugin_skipCmd = 1'b1;
    end
  end

  assign dBus_cmd_valid = (((((execute_arbitration_isValid && execute_MEMORY_ENABLE) && (! execute_arbitration_isStuckByOthers)) && (! execute_arbitration_isFlushed)) && (! execute_DBusSimplePlugin_skipCmd)) && (! _zz_136_));
  assign dBus_cmd_payload_wr = execute_MEMORY_STORE;
  assign dBus_cmd_payload_size = execute_INSTRUCTION[13 : 12];
  always @ (*) begin
    case(dBus_cmd_payload_size)
      2'b00 : begin
        _zz_137_ = {{{execute_RS2[7 : 0],execute_RS2[7 : 0]},execute_RS2[7 : 0]},execute_RS2[7 : 0]};
      end
      2'b01 : begin
        _zz_137_ = {execute_RS2[15 : 0],execute_RS2[15 : 0]};
      end
      default : begin
        _zz_137_ = execute_RS2[31 : 0];
      end
    endcase
  end

  assign dBus_cmd_payload_data = _zz_137_;
  assign _zz_82_ = dBus_cmd_payload_address[1 : 0];
  always @ (*) begin
    case(dBus_cmd_payload_size)
      2'b00 : begin
        _zz_138_ = (4'b0001);
      end
      2'b01 : begin
        _zz_138_ = (4'b0011);
      end
      default : begin
        _zz_138_ = (4'b1111);
      end
    endcase
  end

  assign execute_DBusSimplePlugin_formalMask = (_zz_138_ <<< dBus_cmd_payload_address[1 : 0]);
  assign DBusSimplePlugin_mmuBus_cmd_isValid = (execute_arbitration_isValid && execute_MEMORY_ENABLE);
  assign DBusSimplePlugin_mmuBus_cmd_virtualAddress = execute_SRC_ADD;
  assign DBusSimplePlugin_mmuBus_cmd_bypassTranslation = 1'b0;
  assign DBusSimplePlugin_mmuBus_end = ((! execute_arbitration_isStuck) || execute_arbitration_removeIt);
  assign dBus_cmd_payload_address = DBusSimplePlugin_mmuBus_rsp_physicalAddress;
  assign _zz_81_ = ((execute_MMU_RSP_exception || ((! execute_MMU_RSP_allowWrite) && execute_MEMORY_STORE)) || ((! execute_MMU_RSP_allowRead) && (! execute_MEMORY_STORE)));
  assign _zz_74_ = DBusSimplePlugin_mmuBus_rsp_physicalAddress;
  assign _zz_75_ = DBusSimplePlugin_mmuBus_rsp_isIoAccess;
  assign _zz_76_ = DBusSimplePlugin_mmuBus_rsp_allowRead;
  assign _zz_77_ = DBusSimplePlugin_mmuBus_rsp_allowWrite;
  assign _zz_78_ = DBusSimplePlugin_mmuBus_rsp_allowExecute;
  assign _zz_79_ = DBusSimplePlugin_mmuBus_rsp_exception;
  assign _zz_80_ = DBusSimplePlugin_mmuBus_rsp_refilling;
  assign _zz_73_ = dBus_rsp_data;
  always @ (*) begin
    DBusSimplePlugin_memoryExceptionPort_valid = 1'b0;
    if(_zz_203_)begin
      DBusSimplePlugin_memoryExceptionPort_valid = 1'b1;
    end
    if(memory_ALIGNEMENT_FAULT)begin
      DBusSimplePlugin_memoryExceptionPort_valid = 1'b1;
    end
    if(memory_MMU_RSP_refilling)begin
      DBusSimplePlugin_memoryExceptionPort_valid = 1'b0;
    end else begin
      if(memory_MMU_FAULT)begin
        DBusSimplePlugin_memoryExceptionPort_valid = 1'b1;
      end
    end
    if(_zz_204_)begin
      DBusSimplePlugin_memoryExceptionPort_valid = 1'b0;
    end
  end

  always @ (*) begin
    DBusSimplePlugin_memoryExceptionPort_payload_code = (4'bxxxx);
    if(_zz_203_)begin
      DBusSimplePlugin_memoryExceptionPort_payload_code = (4'b0101);
    end
    if(memory_ALIGNEMENT_FAULT)begin
      DBusSimplePlugin_memoryExceptionPort_payload_code = {1'd0, _zz_241_};
    end
    if(! memory_MMU_RSP_refilling) begin
      if(memory_MMU_FAULT)begin
        DBusSimplePlugin_memoryExceptionPort_payload_code = (memory_MEMORY_STORE ? (4'b1111) : (4'b1101));
      end
    end
  end

  assign DBusSimplePlugin_memoryExceptionPort_payload_badAddr = memory_REGFILE_WRITE_DATA;
  always @ (*) begin
    DBusSimplePlugin_redoBranch_valid = 1'b0;
    if(memory_MMU_RSP_refilling)begin
      DBusSimplePlugin_redoBranch_valid = 1'b1;
    end
    if(_zz_204_)begin
      DBusSimplePlugin_redoBranch_valid = 1'b0;
    end
  end

  assign DBusSimplePlugin_redoBranch_payload = memory_PC;
  always @ (*) begin
    writeBack_DBusSimplePlugin_rspShifted = writeBack_MEMORY_READ_DATA;
    case(writeBack_MEMORY_ADDRESS_LOW)
      2'b01 : begin
        writeBack_DBusSimplePlugin_rspShifted[7 : 0] = writeBack_MEMORY_READ_DATA[15 : 8];
      end
      2'b10 : begin
        writeBack_DBusSimplePlugin_rspShifted[15 : 0] = writeBack_MEMORY_READ_DATA[31 : 16];
      end
      2'b11 : begin
        writeBack_DBusSimplePlugin_rspShifted[7 : 0] = writeBack_MEMORY_READ_DATA[31 : 24];
      end
      default : begin
      end
    endcase
  end

  assign _zz_139_ = (writeBack_DBusSimplePlugin_rspShifted[7] && (! writeBack_INSTRUCTION[14]));
  always @ (*) begin
    _zz_140_[31] = _zz_139_;
    _zz_140_[30] = _zz_139_;
    _zz_140_[29] = _zz_139_;
    _zz_140_[28] = _zz_139_;
    _zz_140_[27] = _zz_139_;
    _zz_140_[26] = _zz_139_;
    _zz_140_[25] = _zz_139_;
    _zz_140_[24] = _zz_139_;
    _zz_140_[23] = _zz_139_;
    _zz_140_[22] = _zz_139_;
    _zz_140_[21] = _zz_139_;
    _zz_140_[20] = _zz_139_;
    _zz_140_[19] = _zz_139_;
    _zz_140_[18] = _zz_139_;
    _zz_140_[17] = _zz_139_;
    _zz_140_[16] = _zz_139_;
    _zz_140_[15] = _zz_139_;
    _zz_140_[14] = _zz_139_;
    _zz_140_[13] = _zz_139_;
    _zz_140_[12] = _zz_139_;
    _zz_140_[11] = _zz_139_;
    _zz_140_[10] = _zz_139_;
    _zz_140_[9] = _zz_139_;
    _zz_140_[8] = _zz_139_;
    _zz_140_[7 : 0] = writeBack_DBusSimplePlugin_rspShifted[7 : 0];
  end

  assign _zz_141_ = (writeBack_DBusSimplePlugin_rspShifted[15] && (! writeBack_INSTRUCTION[14]));
  always @ (*) begin
    _zz_142_[31] = _zz_141_;
    _zz_142_[30] = _zz_141_;
    _zz_142_[29] = _zz_141_;
    _zz_142_[28] = _zz_141_;
    _zz_142_[27] = _zz_141_;
    _zz_142_[26] = _zz_141_;
    _zz_142_[25] = _zz_141_;
    _zz_142_[24] = _zz_141_;
    _zz_142_[23] = _zz_141_;
    _zz_142_[22] = _zz_141_;
    _zz_142_[21] = _zz_141_;
    _zz_142_[20] = _zz_141_;
    _zz_142_[19] = _zz_141_;
    _zz_142_[18] = _zz_141_;
    _zz_142_[17] = _zz_141_;
    _zz_142_[16] = _zz_141_;
    _zz_142_[15 : 0] = writeBack_DBusSimplePlugin_rspShifted[15 : 0];
  end

  always @ (*) begin
    case(_zz_220_)
      2'b00 : begin
        writeBack_DBusSimplePlugin_rspFormated = _zz_140_;
      end
      2'b01 : begin
        writeBack_DBusSimplePlugin_rspFormated = _zz_142_;
      end
      default : begin
        writeBack_DBusSimplePlugin_rspFormated = writeBack_DBusSimplePlugin_rspShifted;
      end
    endcase
  end

  assign IBusSimplePlugin_mmuBus_rsp_physicalAddress = IBusSimplePlugin_mmuBus_cmd_virtualAddress;
  assign IBusSimplePlugin_mmuBus_rsp_allowRead = 1'b1;
  assign IBusSimplePlugin_mmuBus_rsp_allowWrite = 1'b1;
  assign IBusSimplePlugin_mmuBus_rsp_allowExecute = 1'b1;
  assign IBusSimplePlugin_mmuBus_rsp_isIoAccess = IBusSimplePlugin_mmuBus_rsp_physicalAddress[31];
  assign IBusSimplePlugin_mmuBus_rsp_exception = 1'b0;
  assign IBusSimplePlugin_mmuBus_rsp_refilling = 1'b0;
  assign IBusSimplePlugin_mmuBus_busy = 1'b0;
  assign DBusSimplePlugin_mmuBus_rsp_physicalAddress = DBusSimplePlugin_mmuBus_cmd_virtualAddress;
  assign DBusSimplePlugin_mmuBus_rsp_allowRead = 1'b1;
  assign DBusSimplePlugin_mmuBus_rsp_allowWrite = 1'b1;
  assign DBusSimplePlugin_mmuBus_rsp_allowExecute = 1'b1;
  assign DBusSimplePlugin_mmuBus_rsp_isIoAccess = DBusSimplePlugin_mmuBus_rsp_physicalAddress[31];
  assign DBusSimplePlugin_mmuBus_rsp_exception = 1'b0;
  assign DBusSimplePlugin_mmuBus_rsp_refilling = 1'b0;
  assign DBusSimplePlugin_mmuBus_busy = 1'b0;
  assign _zz_144_ = ((decode_INSTRUCTION & (32'b00000000000000000100000001010000)) == (32'b00000000000000000100000001010000));
  assign _zz_145_ = ((decode_INSTRUCTION & (32'b00000000000000000000000001001000)) == (32'b00000000000000000000000001001000));
  assign _zz_146_ = ((decode_INSTRUCTION & (32'b00000000000000000000000001010000)) == (32'b00000000000000000000000000010000));
  assign _zz_147_ = ((decode_INSTRUCTION & (32'b00000000000000000000000000000100)) == (32'b00000000000000000000000000000100));
  assign _zz_143_ = {(((decode_INSTRUCTION & _zz_288_) == (32'b00000000000000000000000000000000)) != (1'b0)),{({_zz_289_,_zz_290_} != (2'b00)),{(_zz_291_ != (1'b0)),{(_zz_292_ != _zz_293_),{_zz_294_,{_zz_295_,_zz_296_}}}}}};
  assign _zz_71_ = ({((decode_INSTRUCTION & (32'b00000000000000000000000001011111)) == (32'b00000000000000000000000000010111)),{((decode_INSTRUCTION & (32'b00000000000000000000000001111111)) == (32'b00000000000000000000000001101111)),{((decode_INSTRUCTION & (32'b00000000000000000001000001101111)) == (32'b00000000000000000000000000000011)),{((decode_INSTRUCTION & _zz_408_) == (32'b00000000000000000001000001110011)),{(_zz_409_ == _zz_410_),{_zz_411_,{_zz_412_,_zz_413_}}}}}}} != (18'b000000000000000000));
  assign _zz_148_ = _zz_143_[1 : 0];
  assign _zz_70_ = _zz_148_;
  assign _zz_149_ = _zz_143_[3 : 2];
  assign _zz_69_ = _zz_149_;
  assign _zz_68_ = _zz_242_[0];
  assign _zz_67_ = _zz_243_[0];
  assign _zz_66_ = _zz_244_[0];
  assign _zz_65_ = _zz_245_[0];
  assign _zz_64_ = _zz_246_[0];
  assign _zz_63_ = _zz_247_[0];
  assign _zz_62_ = _zz_248_[0];
  assign _zz_150_ = _zz_143_[13 : 12];
  assign _zz_61_ = _zz_150_;
  assign _zz_151_ = _zz_143_[15 : 14];
  assign _zz_60_ = _zz_151_;
  assign _zz_152_ = _zz_143_[16 : 16];
  assign _zz_59_ = _zz_152_;
  assign _zz_58_ = _zz_249_[0];
  assign _zz_153_ = _zz_143_[19 : 18];
  assign _zz_57_ = _zz_153_;
  assign _zz_56_ = _zz_250_[0];
  assign _zz_154_ = _zz_143_[22 : 21];
  assign _zz_55_ = _zz_154_;
  assign _zz_54_ = _zz_251_[0];
  assign _zz_53_ = _zz_252_[0];
  assign decodeExceptionPort_valid = ((decode_arbitration_isValid && decode_INSTRUCTION_READY) && (! decode_LEGAL_INSTRUCTION));
  assign decodeExceptionPort_payload_code = (4'b0010);
  assign decodeExceptionPort_payload_badAddr = decode_INSTRUCTION;
  assign decode_RegFilePlugin_regFileReadAddress1 = decode_INSTRUCTION_ANTICIPATED[19 : 15];
  assign decode_RegFilePlugin_regFileReadAddress2 = decode_INSTRUCTION_ANTICIPATED[24 : 20];
  assign decode_RegFilePlugin_rs1Data = _zz_190_;
  assign decode_RegFilePlugin_rs2Data = _zz_191_;
  assign _zz_52_ = decode_RegFilePlugin_rs1Data;
  assign _zz_51_ = decode_RegFilePlugin_rs2Data;
  always @ (*) begin
    lastStageRegFileWrite_valid = (_zz_49_ && writeBack_arbitration_isFiring);
    if(_zz_155_)begin
      lastStageRegFileWrite_valid = 1'b1;
    end
  end

  assign lastStageRegFileWrite_payload_address = _zz_48_[11 : 7];
  assign lastStageRegFileWrite_payload_data = _zz_72_;
  always @ (*) begin
    case(execute_ALU_BITWISE_CTRL)
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : begin
        execute_IntAluPlugin_bitwise = (execute_SRC1 & execute_SRC2);
      end
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : begin
        execute_IntAluPlugin_bitwise = (execute_SRC1 | execute_SRC2);
      end
      default : begin
        execute_IntAluPlugin_bitwise = (execute_SRC1 ^ execute_SRC2);
      end
    endcase
  end

  always @ (*) begin
    case(execute_ALU_CTRL)
      `AluCtrlEnum_defaultEncoding_BITWISE : begin
        _zz_156_ = execute_IntAluPlugin_bitwise;
      end
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : begin
        _zz_156_ = {31'd0, _zz_253_};
      end
      default : begin
        _zz_156_ = execute_SRC_ADD_SUB;
      end
    endcase
  end

  assign _zz_46_ = _zz_156_;
  assign _zz_44_ = (decode_SRC_ADD_ZERO && (! decode_SRC_USE_SUB_LESS));
  always @ (*) begin
    case(execute_SRC1_CTRL)
      `Src1CtrlEnum_defaultEncoding_RS : begin
        _zz_157_ = execute_RS1;
      end
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : begin
        _zz_157_ = {29'd0, _zz_254_};
      end
      `Src1CtrlEnum_defaultEncoding_IMU : begin
        _zz_157_ = {execute_INSTRUCTION[31 : 12],(12'b000000000000)};
      end
      default : begin
        _zz_157_ = {27'd0, _zz_255_};
      end
    endcase
  end

  assign _zz_43_ = _zz_157_;
  assign _zz_158_ = _zz_256_[11];
  always @ (*) begin
    _zz_159_[19] = _zz_158_;
    _zz_159_[18] = _zz_158_;
    _zz_159_[17] = _zz_158_;
    _zz_159_[16] = _zz_158_;
    _zz_159_[15] = _zz_158_;
    _zz_159_[14] = _zz_158_;
    _zz_159_[13] = _zz_158_;
    _zz_159_[12] = _zz_158_;
    _zz_159_[11] = _zz_158_;
    _zz_159_[10] = _zz_158_;
    _zz_159_[9] = _zz_158_;
    _zz_159_[8] = _zz_158_;
    _zz_159_[7] = _zz_158_;
    _zz_159_[6] = _zz_158_;
    _zz_159_[5] = _zz_158_;
    _zz_159_[4] = _zz_158_;
    _zz_159_[3] = _zz_158_;
    _zz_159_[2] = _zz_158_;
    _zz_159_[1] = _zz_158_;
    _zz_159_[0] = _zz_158_;
  end

  assign _zz_160_ = _zz_257_[11];
  always @ (*) begin
    _zz_161_[19] = _zz_160_;
    _zz_161_[18] = _zz_160_;
    _zz_161_[17] = _zz_160_;
    _zz_161_[16] = _zz_160_;
    _zz_161_[15] = _zz_160_;
    _zz_161_[14] = _zz_160_;
    _zz_161_[13] = _zz_160_;
    _zz_161_[12] = _zz_160_;
    _zz_161_[11] = _zz_160_;
    _zz_161_[10] = _zz_160_;
    _zz_161_[9] = _zz_160_;
    _zz_161_[8] = _zz_160_;
    _zz_161_[7] = _zz_160_;
    _zz_161_[6] = _zz_160_;
    _zz_161_[5] = _zz_160_;
    _zz_161_[4] = _zz_160_;
    _zz_161_[3] = _zz_160_;
    _zz_161_[2] = _zz_160_;
    _zz_161_[1] = _zz_160_;
    _zz_161_[0] = _zz_160_;
  end

  always @ (*) begin
    case(execute_SRC2_CTRL)
      `Src2CtrlEnum_defaultEncoding_RS : begin
        _zz_162_ = execute_RS2;
      end
      `Src2CtrlEnum_defaultEncoding_IMI : begin
        _zz_162_ = {_zz_159_,execute_INSTRUCTION[31 : 20]};
      end
      `Src2CtrlEnum_defaultEncoding_IMS : begin
        _zz_162_ = {_zz_161_,{execute_INSTRUCTION[31 : 25],execute_INSTRUCTION[11 : 7]}};
      end
      default : begin
        _zz_162_ = _zz_39_;
      end
    endcase
  end

  assign _zz_41_ = _zz_162_;
  always @ (*) begin
    execute_SrcPlugin_addSub = _zz_258_;
    if(execute_SRC2_FORCE_ZERO)begin
      execute_SrcPlugin_addSub = execute_SRC1;
    end
  end

  assign execute_SrcPlugin_less = ((execute_SRC1[31] == execute_SRC2[31]) ? execute_SrcPlugin_addSub[31] : (execute_SRC_LESS_UNSIGNED ? execute_SRC2[31] : execute_SRC1[31]));
  assign _zz_38_ = execute_SrcPlugin_addSub;
  assign _zz_37_ = execute_SrcPlugin_addSub;
  assign _zz_36_ = execute_SrcPlugin_less;
  assign execute_LightShifterPlugin_isShift = (execute_SHIFT_CTRL != `ShiftCtrlEnum_defaultEncoding_DISABLE_1);
  assign execute_LightShifterPlugin_amplitude = (execute_LightShifterPlugin_isActive ? execute_LightShifterPlugin_amplitudeReg : execute_SRC2[4 : 0]);
  assign execute_LightShifterPlugin_shiftInput = (execute_LightShifterPlugin_isActive ? memory_REGFILE_WRITE_DATA : execute_SRC1);
  assign execute_LightShifterPlugin_done = (execute_LightShifterPlugin_amplitude[4 : 1] == (4'b0000));
  always @ (*) begin
    case(execute_SHIFT_CTRL)
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : begin
        _zz_163_ = (execute_LightShifterPlugin_shiftInput <<< 1);
      end
      default : begin
        _zz_163_ = _zz_265_;
      end
    endcase
  end

  always @ (*) begin
    _zz_164_ = 1'b0;
    if(_zz_167_)begin
      if((_zz_168_ == decode_INSTRUCTION[19 : 15]))begin
        _zz_164_ = 1'b1;
      end
    end
    if(_zz_205_)begin
      if(_zz_206_)begin
        if((writeBack_INSTRUCTION[11 : 7] == decode_INSTRUCTION[19 : 15]))begin
          _zz_164_ = 1'b1;
        end
      end
    end
    if(_zz_207_)begin
      if(_zz_208_)begin
        if((memory_INSTRUCTION[11 : 7] == decode_INSTRUCTION[19 : 15]))begin
          _zz_164_ = 1'b1;
        end
      end
    end
    if(_zz_209_)begin
      if(_zz_210_)begin
        if((execute_INSTRUCTION[11 : 7] == decode_INSTRUCTION[19 : 15]))begin
          _zz_164_ = 1'b1;
        end
      end
    end
    if((! decode_RS1_USE))begin
      _zz_164_ = 1'b0;
    end
  end

  always @ (*) begin
    _zz_165_ = 1'b0;
    if(_zz_167_)begin
      if((_zz_168_ == decode_INSTRUCTION[24 : 20]))begin
        _zz_165_ = 1'b1;
      end
    end
    if(_zz_205_)begin
      if(_zz_206_)begin
        if((writeBack_INSTRUCTION[11 : 7] == decode_INSTRUCTION[24 : 20]))begin
          _zz_165_ = 1'b1;
        end
      end
    end
    if(_zz_207_)begin
      if(_zz_208_)begin
        if((memory_INSTRUCTION[11 : 7] == decode_INSTRUCTION[24 : 20]))begin
          _zz_165_ = 1'b1;
        end
      end
    end
    if(_zz_209_)begin
      if(_zz_210_)begin
        if((execute_INSTRUCTION[11 : 7] == decode_INSTRUCTION[24 : 20]))begin
          _zz_165_ = 1'b1;
        end
      end
    end
    if((! decode_RS2_USE))begin
      _zz_165_ = 1'b0;
    end
  end

  assign _zz_166_ = (_zz_49_ && writeBack_arbitration_isFiring);
  assign execute_BranchPlugin_eq = (execute_SRC1 == execute_SRC2);
  assign _zz_169_ = execute_INSTRUCTION[14 : 12];
  always @ (*) begin
    if((_zz_169_ == (3'b000))) begin
        _zz_170_ = execute_BranchPlugin_eq;
    end else if((_zz_169_ == (3'b001))) begin
        _zz_170_ = (! execute_BranchPlugin_eq);
    end else if((((_zz_169_ & (3'b101)) == (3'b101)))) begin
        _zz_170_ = (! execute_SRC_LESS);
    end else begin
        _zz_170_ = execute_SRC_LESS;
    end
  end

  always @ (*) begin
    case(execute_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_INC : begin
        _zz_171_ = 1'b0;
      end
      `BranchCtrlEnum_defaultEncoding_JAL : begin
        _zz_171_ = 1'b1;
      end
      `BranchCtrlEnum_defaultEncoding_JALR : begin
        _zz_171_ = 1'b1;
      end
      default : begin
        _zz_171_ = _zz_170_;
      end
    endcase
  end

  assign _zz_33_ = _zz_171_;
  assign execute_BranchPlugin_branch_src1 = ((execute_BRANCH_CTRL == `BranchCtrlEnum_defaultEncoding_JALR) ? execute_RS1 : execute_PC);
  assign _zz_172_ = _zz_267_[19];
  always @ (*) begin
    _zz_173_[10] = _zz_172_;
    _zz_173_[9] = _zz_172_;
    _zz_173_[8] = _zz_172_;
    _zz_173_[7] = _zz_172_;
    _zz_173_[6] = _zz_172_;
    _zz_173_[5] = _zz_172_;
    _zz_173_[4] = _zz_172_;
    _zz_173_[3] = _zz_172_;
    _zz_173_[2] = _zz_172_;
    _zz_173_[1] = _zz_172_;
    _zz_173_[0] = _zz_172_;
  end

  assign _zz_174_ = _zz_268_[11];
  always @ (*) begin
    _zz_175_[19] = _zz_174_;
    _zz_175_[18] = _zz_174_;
    _zz_175_[17] = _zz_174_;
    _zz_175_[16] = _zz_174_;
    _zz_175_[15] = _zz_174_;
    _zz_175_[14] = _zz_174_;
    _zz_175_[13] = _zz_174_;
    _zz_175_[12] = _zz_174_;
    _zz_175_[11] = _zz_174_;
    _zz_175_[10] = _zz_174_;
    _zz_175_[9] = _zz_174_;
    _zz_175_[8] = _zz_174_;
    _zz_175_[7] = _zz_174_;
    _zz_175_[6] = _zz_174_;
    _zz_175_[5] = _zz_174_;
    _zz_175_[4] = _zz_174_;
    _zz_175_[3] = _zz_174_;
    _zz_175_[2] = _zz_174_;
    _zz_175_[1] = _zz_174_;
    _zz_175_[0] = _zz_174_;
  end

  assign _zz_176_ = _zz_269_[11];
  always @ (*) begin
    _zz_177_[18] = _zz_176_;
    _zz_177_[17] = _zz_176_;
    _zz_177_[16] = _zz_176_;
    _zz_177_[15] = _zz_176_;
    _zz_177_[14] = _zz_176_;
    _zz_177_[13] = _zz_176_;
    _zz_177_[12] = _zz_176_;
    _zz_177_[11] = _zz_176_;
    _zz_177_[10] = _zz_176_;
    _zz_177_[9] = _zz_176_;
    _zz_177_[8] = _zz_176_;
    _zz_177_[7] = _zz_176_;
    _zz_177_[6] = _zz_176_;
    _zz_177_[5] = _zz_176_;
    _zz_177_[4] = _zz_176_;
    _zz_177_[3] = _zz_176_;
    _zz_177_[2] = _zz_176_;
    _zz_177_[1] = _zz_176_;
    _zz_177_[0] = _zz_176_;
  end

  always @ (*) begin
    case(execute_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_JAL : begin
        _zz_178_ = {{_zz_173_,{{{execute_INSTRUCTION[31],execute_INSTRUCTION[19 : 12]},execute_INSTRUCTION[20]},execute_INSTRUCTION[30 : 21]}},1'b0};
      end
      `BranchCtrlEnum_defaultEncoding_JALR : begin
        _zz_178_ = {_zz_175_,execute_INSTRUCTION[31 : 20]};
      end
      default : begin
        _zz_178_ = {{_zz_177_,{{{execute_INSTRUCTION[31],execute_INSTRUCTION[7]},execute_INSTRUCTION[30 : 25]},execute_INSTRUCTION[11 : 8]}},1'b0};
      end
    endcase
  end

  assign execute_BranchPlugin_branch_src2 = _zz_178_;
  assign execute_BranchPlugin_branchAdder = (execute_BranchPlugin_branch_src1 + execute_BranchPlugin_branch_src2);
  assign _zz_31_ = {execute_BranchPlugin_branchAdder[31 : 1],(1'b0)};
  assign BranchPlugin_jumpInterface_valid = ((memory_arbitration_isValid && (! memory_arbitration_isStuckByOthers)) && memory_BRANCH_DO);
  assign BranchPlugin_jumpInterface_payload = memory_BRANCH_CALC;
  always @ (*) begin
    CsrPlugin_privilege = (2'b11);
    if(CsrPlugin_forceMachineWire)begin
      CsrPlugin_privilege = (2'b11);
    end
  end

  assign CsrPlugin_misa_base = (2'b01);
  assign CsrPlugin_misa_extensions = (26'b00000000000000000001000010);
  assign _zz_179_ = (CsrPlugin_mip_MTIP && CsrPlugin_mie_MTIE);
  assign _zz_180_ = (CsrPlugin_mip_MSIP && CsrPlugin_mie_MSIE);
  assign _zz_181_ = (CsrPlugin_mip_MEIP && CsrPlugin_mie_MEIE);
  assign CsrPlugin_exceptionPortCtrl_exceptionTargetPrivilegeUncapped = (2'b11);
  assign CsrPlugin_exceptionPortCtrl_exceptionTargetPrivilege = ((CsrPlugin_privilege < CsrPlugin_exceptionPortCtrl_exceptionTargetPrivilegeUncapped) ? CsrPlugin_exceptionPortCtrl_exceptionTargetPrivilegeUncapped : CsrPlugin_privilege);
  assign _zz_182_ = {decodeExceptionPort_valid,IBusSimplePlugin_decodeExceptionPort_valid};
  assign _zz_183_ = _zz_270_[0];
  always @ (*) begin
    CsrPlugin_exceptionPortCtrl_exceptionValids_decode = CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_decode;
    if(_zz_195_)begin
      CsrPlugin_exceptionPortCtrl_exceptionValids_decode = 1'b1;
    end
    if(decode_arbitration_isFlushed)begin
      CsrPlugin_exceptionPortCtrl_exceptionValids_decode = 1'b0;
    end
  end

  always @ (*) begin
    CsrPlugin_exceptionPortCtrl_exceptionValids_execute = CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_execute;
    if(execute_arbitration_isFlushed)begin
      CsrPlugin_exceptionPortCtrl_exceptionValids_execute = 1'b0;
    end
  end

  always @ (*) begin
    CsrPlugin_exceptionPortCtrl_exceptionValids_memory = CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_memory;
    if(DBusSimplePlugin_memoryExceptionPort_valid)begin
      CsrPlugin_exceptionPortCtrl_exceptionValids_memory = 1'b1;
    end
    if(memory_arbitration_isFlushed)begin
      CsrPlugin_exceptionPortCtrl_exceptionValids_memory = 1'b0;
    end
  end

  always @ (*) begin
    CsrPlugin_exceptionPortCtrl_exceptionValids_writeBack = CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_writeBack;
    if(writeBack_arbitration_isFlushed)begin
      CsrPlugin_exceptionPortCtrl_exceptionValids_writeBack = 1'b0;
    end
  end

  assign CsrPlugin_exceptionPendings_0 = CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_decode;
  assign CsrPlugin_exceptionPendings_1 = CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_execute;
  assign CsrPlugin_exceptionPendings_2 = CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_memory;
  assign CsrPlugin_exceptionPendings_3 = CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_writeBack;
  assign CsrPlugin_exception = (CsrPlugin_exceptionPortCtrl_exceptionValids_writeBack && CsrPlugin_allowException);
  assign CsrPlugin_lastStageWasWfi = 1'b0;
  always @ (*) begin
    CsrPlugin_pipelineLiberator_done = ((! ({writeBack_arbitration_isValid,{memory_arbitration_isValid,execute_arbitration_isValid}} != (3'b000))) && IBusSimplePlugin_pcValids_3);
    if(({CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_writeBack,{CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_memory,CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_execute}} != (3'b000)))begin
      CsrPlugin_pipelineLiberator_done = 1'b0;
    end
    if(CsrPlugin_hadException)begin
      CsrPlugin_pipelineLiberator_done = 1'b0;
    end
  end

  assign CsrPlugin_interruptJump = ((CsrPlugin_interrupt_valid && CsrPlugin_pipelineLiberator_done) && CsrPlugin_allowInterrupts);
  always @ (*) begin
    CsrPlugin_targetPrivilege = CsrPlugin_interrupt_targetPrivilege;
    if(CsrPlugin_hadException)begin
      CsrPlugin_targetPrivilege = CsrPlugin_exceptionPortCtrl_exceptionTargetPrivilege;
    end
  end

  always @ (*) begin
    CsrPlugin_trapCause = CsrPlugin_interrupt_code;
    if(CsrPlugin_hadException)begin
      CsrPlugin_trapCause = CsrPlugin_exceptionPortCtrl_exceptionContext_code;
    end
  end

  always @ (*) begin
    CsrPlugin_xtvec_mode = (2'bxx);
    case(CsrPlugin_targetPrivilege)
      2'b11 : begin
        CsrPlugin_xtvec_mode = CsrPlugin_mtvec_mode;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    CsrPlugin_xtvec_base = (30'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
    case(CsrPlugin_targetPrivilege)
      2'b11 : begin
        CsrPlugin_xtvec_base = CsrPlugin_mtvec_base;
      end
      default : begin
      end
    endcase
  end

  assign contextSwitching = CsrPlugin_jumpInterface_valid;
  assign _zz_29_ = (! (((decode_INSTRUCTION[14 : 13] == (2'b01)) && (decode_INSTRUCTION[19 : 15] == (5'b00000))) || ((decode_INSTRUCTION[14 : 13] == (2'b11)) && (decode_INSTRUCTION[19 : 15] == (5'b00000)))));
  assign _zz_28_ = (decode_INSTRUCTION[13 : 7] != (7'b0100000));
  assign execute_CsrPlugin_inWfi = 1'b0;
  assign execute_CsrPlugin_blockedBySideEffects = ({writeBack_arbitration_isValid,memory_arbitration_isValid} != (2'b00));
  always @ (*) begin
    execute_CsrPlugin_illegalAccess = 1'b1;
    case(execute_CsrPlugin_csrAddress)
      12'b101111000000 : begin
        execute_CsrPlugin_illegalAccess = 1'b0;
      end
      12'b001100000000 : begin
        execute_CsrPlugin_illegalAccess = 1'b0;
      end
      12'b001101000001 : begin
        execute_CsrPlugin_illegalAccess = 1'b0;
      end
      12'b001100000101 : begin
        if(execute_CSR_WRITE_OPCODE)begin
          execute_CsrPlugin_illegalAccess = 1'b0;
        end
      end
      12'b001101000100 : begin
        execute_CsrPlugin_illegalAccess = 1'b0;
      end
      12'b001101000011 : begin
        if(execute_CSR_READ_OPCODE)begin
          execute_CsrPlugin_illegalAccess = 1'b0;
        end
      end
      12'b111111000000 : begin
        if(execute_CSR_READ_OPCODE)begin
          execute_CsrPlugin_illegalAccess = 1'b0;
        end
      end
      12'b001100000100 : begin
        execute_CsrPlugin_illegalAccess = 1'b0;
      end
      12'b001101000010 : begin
        if(execute_CSR_READ_OPCODE)begin
          execute_CsrPlugin_illegalAccess = 1'b0;
        end
      end
      default : begin
      end
    endcase
    if((CsrPlugin_privilege < execute_CsrPlugin_csrAddress[9 : 8]))begin
      execute_CsrPlugin_illegalAccess = 1'b1;
    end
    if(((! execute_arbitration_isValid) || (! execute_IS_CSR)))begin
      execute_CsrPlugin_illegalAccess = 1'b0;
    end
  end

  always @ (*) begin
    execute_CsrPlugin_illegalInstruction = 1'b0;
    if((execute_arbitration_isValid && (execute_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET)))begin
      if((CsrPlugin_privilege < execute_INSTRUCTION[29 : 28]))begin
        execute_CsrPlugin_illegalInstruction = 1'b1;
      end
    end
  end

  always @ (*) begin
    execute_CsrPlugin_readData = (32'b00000000000000000000000000000000);
    case(execute_CsrPlugin_csrAddress)
      12'b101111000000 : begin
        execute_CsrPlugin_readData[31 : 0] = _zz_184_;
      end
      12'b001100000000 : begin
        execute_CsrPlugin_readData[12 : 11] = CsrPlugin_mstatus_MPP;
        execute_CsrPlugin_readData[7 : 7] = CsrPlugin_mstatus_MPIE;
        execute_CsrPlugin_readData[3 : 3] = CsrPlugin_mstatus_MIE;
      end
      12'b001101000001 : begin
        execute_CsrPlugin_readData[31 : 0] = CsrPlugin_mepc;
      end
      12'b001100000101 : begin
      end
      12'b001101000100 : begin
        execute_CsrPlugin_readData[11 : 11] = CsrPlugin_mip_MEIP;
        execute_CsrPlugin_readData[7 : 7] = CsrPlugin_mip_MTIP;
        execute_CsrPlugin_readData[3 : 3] = CsrPlugin_mip_MSIP;
      end
      12'b001101000011 : begin
        execute_CsrPlugin_readData[31 : 0] = CsrPlugin_mtval;
      end
      12'b111111000000 : begin
        execute_CsrPlugin_readData[31 : 0] = _zz_185_;
      end
      12'b001100000100 : begin
        execute_CsrPlugin_readData[11 : 11] = CsrPlugin_mie_MEIE;
        execute_CsrPlugin_readData[7 : 7] = CsrPlugin_mie_MTIE;
        execute_CsrPlugin_readData[3 : 3] = CsrPlugin_mie_MSIE;
      end
      12'b001101000010 : begin
        execute_CsrPlugin_readData[31 : 31] = CsrPlugin_mcause_interrupt;
        execute_CsrPlugin_readData[3 : 0] = CsrPlugin_mcause_exceptionCode;
      end
      default : begin
      end
    endcase
  end

  assign execute_CsrPlugin_writeInstruction = ((execute_arbitration_isValid && execute_IS_CSR) && execute_CSR_WRITE_OPCODE);
  assign execute_CsrPlugin_readInstruction = ((execute_arbitration_isValid && execute_IS_CSR) && execute_CSR_READ_OPCODE);
  assign execute_CsrPlugin_writeEnable = ((execute_CsrPlugin_writeInstruction && (! execute_CsrPlugin_blockedBySideEffects)) && (! execute_arbitration_isStuckByOthers));
  assign execute_CsrPlugin_readEnable = ((execute_CsrPlugin_readInstruction && (! execute_CsrPlugin_blockedBySideEffects)) && (! execute_arbitration_isStuckByOthers));
  assign execute_CsrPlugin_readToWriteData = execute_CsrPlugin_readData;
  always @ (*) begin
    case(_zz_221_)
      1'b0 : begin
        execute_CsrPlugin_writeData = execute_SRC1;
      end
      default : begin
        execute_CsrPlugin_writeData = (execute_INSTRUCTION[12] ? (execute_CsrPlugin_readToWriteData & (~ execute_SRC1)) : (execute_CsrPlugin_readToWriteData | execute_SRC1));
      end
    endcase
  end

  assign execute_CsrPlugin_csrAddress = execute_INSTRUCTION[31 : 20];
  assign _zz_185_ = (_zz_184_ & externalInterruptArray_regNext);
  assign externalInterrupt = (_zz_185_ != (32'b00000000000000000000000000000000));
  assign _zz_25_ = decode_BRANCH_CTRL;
  assign _zz_23_ = _zz_69_;
  assign _zz_32_ = decode_to_execute_BRANCH_CTRL;
  assign _zz_22_ = decode_SHIFT_CTRL;
  assign _zz_20_ = _zz_55_;
  assign _zz_35_ = decode_to_execute_SHIFT_CTRL;
  assign _zz_19_ = decode_ALU_CTRL;
  assign _zz_17_ = _zz_60_;
  assign _zz_45_ = decode_to_execute_ALU_CTRL;
  assign _zz_16_ = decode_ENV_CTRL;
  assign _zz_13_ = execute_ENV_CTRL;
  assign _zz_11_ = memory_ENV_CTRL;
  assign _zz_14_ = _zz_59_;
  assign _zz_27_ = decode_to_execute_ENV_CTRL;
  assign _zz_26_ = execute_to_memory_ENV_CTRL;
  assign _zz_30_ = memory_to_writeBack_ENV_CTRL;
  assign _zz_9_ = decode_SRC2_CTRL;
  assign _zz_7_ = _zz_61_;
  assign _zz_40_ = decode_to_execute_SRC2_CTRL;
  assign _zz_6_ = decode_SRC1_CTRL;
  assign _zz_4_ = _zz_70_;
  assign _zz_42_ = decode_to_execute_SRC1_CTRL;
  assign _zz_3_ = decode_ALU_BITWISE_CTRL;
  assign _zz_1_ = _zz_57_;
  assign _zz_47_ = decode_to_execute_ALU_BITWISE_CTRL;
  assign decode_arbitration_isFlushed = ({writeBack_arbitration_flushAll,{memory_arbitration_flushAll,{execute_arbitration_flushAll,decode_arbitration_flushAll}}} != (4'b0000));
  assign execute_arbitration_isFlushed = ({writeBack_arbitration_flushAll,{memory_arbitration_flushAll,execute_arbitration_flushAll}} != (3'b000));
  assign memory_arbitration_isFlushed = ({writeBack_arbitration_flushAll,memory_arbitration_flushAll} != (2'b00));
  assign writeBack_arbitration_isFlushed = (writeBack_arbitration_flushAll != (1'b0));
  assign decode_arbitration_isStuckByOthers = (decode_arbitration_haltByOther || (((1'b0 || execute_arbitration_isStuck) || memory_arbitration_isStuck) || writeBack_arbitration_isStuck));
  assign decode_arbitration_isStuck = (decode_arbitration_haltItself || decode_arbitration_isStuckByOthers);
  assign decode_arbitration_isMoving = ((! decode_arbitration_isStuck) && (! decode_arbitration_removeIt));
  assign decode_arbitration_isFiring = ((decode_arbitration_isValid && (! decode_arbitration_isStuck)) && (! decode_arbitration_removeIt));
  assign execute_arbitration_isStuckByOthers = (execute_arbitration_haltByOther || ((1'b0 || memory_arbitration_isStuck) || writeBack_arbitration_isStuck));
  assign execute_arbitration_isStuck = (execute_arbitration_haltItself || execute_arbitration_isStuckByOthers);
  assign execute_arbitration_isMoving = ((! execute_arbitration_isStuck) && (! execute_arbitration_removeIt));
  assign execute_arbitration_isFiring = ((execute_arbitration_isValid && (! execute_arbitration_isStuck)) && (! execute_arbitration_removeIt));
  assign memory_arbitration_isStuckByOthers = (memory_arbitration_haltByOther || (1'b0 || writeBack_arbitration_isStuck));
  assign memory_arbitration_isStuck = (memory_arbitration_haltItself || memory_arbitration_isStuckByOthers);
  assign memory_arbitration_isMoving = ((! memory_arbitration_isStuck) && (! memory_arbitration_removeIt));
  assign memory_arbitration_isFiring = ((memory_arbitration_isValid && (! memory_arbitration_isStuck)) && (! memory_arbitration_removeIt));
  assign writeBack_arbitration_isStuckByOthers = (writeBack_arbitration_haltByOther || 1'b0);
  assign writeBack_arbitration_isStuck = (writeBack_arbitration_haltItself || writeBack_arbitration_isStuckByOthers);
  assign writeBack_arbitration_isMoving = ((! writeBack_arbitration_isStuck) && (! writeBack_arbitration_removeIt));
  assign writeBack_arbitration_isFiring = ((writeBack_arbitration_isValid && (! writeBack_arbitration_isStuck)) && (! writeBack_arbitration_removeIt));
  assign iBus_cmd_ready = ((1'b1 && (! iBus_cmd_m2sPipe_valid)) || iBus_cmd_m2sPipe_ready);
  assign iBus_cmd_m2sPipe_valid = _zz_186_;
  assign iBus_cmd_m2sPipe_payload_pc = _zz_187_;
  assign iBusWishbone_ADR = (iBus_cmd_m2sPipe_payload_pc >>> 2);
  assign iBusWishbone_CTI = (3'b000);
  assign iBusWishbone_BTE = (2'b00);
  assign iBusWishbone_SEL = (4'b1111);
  assign iBusWishbone_WE = 1'b0;
  assign iBusWishbone_DAT_MOSI = (32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx);
  assign iBusWishbone_CYC = iBus_cmd_m2sPipe_valid;
  assign iBusWishbone_STB = iBus_cmd_m2sPipe_valid;
  assign iBus_cmd_m2sPipe_ready = (iBus_cmd_m2sPipe_valid && iBusWishbone_ACK);
  assign iBus_rsp_valid = (iBusWishbone_CYC && iBusWishbone_ACK);
  assign iBus_rsp_payload_inst = iBusWishbone_DAT_MISO;
  assign iBus_rsp_payload_error = 1'b0;
  assign dBus_cmd_halfPipe_valid = dBus_cmd_halfPipe_regs_valid;
  assign dBus_cmd_halfPipe_payload_wr = dBus_cmd_halfPipe_regs_payload_wr;
  assign dBus_cmd_halfPipe_payload_address = dBus_cmd_halfPipe_regs_payload_address;
  assign dBus_cmd_halfPipe_payload_data = dBus_cmd_halfPipe_regs_payload_data;
  assign dBus_cmd_halfPipe_payload_size = dBus_cmd_halfPipe_regs_payload_size;
  assign dBus_cmd_ready = dBus_cmd_halfPipe_regs_ready;
  assign dBusWishbone_ADR = (dBus_cmd_halfPipe_payload_address >>> 2);
  assign dBusWishbone_CTI = (3'b000);
  assign dBusWishbone_BTE = (2'b00);
  always @ (*) begin
    case(dBus_cmd_halfPipe_payload_size)
      2'b00 : begin
        _zz_188_ = (4'b0001);
      end
      2'b01 : begin
        _zz_188_ = (4'b0011);
      end
      default : begin
        _zz_188_ = (4'b1111);
      end
    endcase
  end

  always @ (*) begin
    dBusWishbone_SEL = _zz_278_[3:0];
    if((! dBus_cmd_halfPipe_payload_wr))begin
      dBusWishbone_SEL = (4'b1111);
    end
  end

  assign dBusWishbone_WE = dBus_cmd_halfPipe_payload_wr;
  assign dBusWishbone_DAT_MOSI = dBus_cmd_halfPipe_payload_data;
  assign dBus_cmd_halfPipe_ready = (dBus_cmd_halfPipe_valid && dBusWishbone_ACK);
  assign dBusWishbone_CYC = dBus_cmd_halfPipe_valid;
  assign dBusWishbone_STB = dBus_cmd_halfPipe_valid;
  assign dBus_rsp_ready = ((dBus_cmd_halfPipe_valid && (! dBusWishbone_WE)) && dBusWishbone_ACK);
  assign dBus_rsp_data = dBusWishbone_DAT_MISO;
  assign dBus_rsp_error = 1'b0;
  always @ (posedge clk) begin
    if(reset) begin
      IBusSimplePlugin_fetchPc_pcReg <= externalResetVector;
      IBusSimplePlugin_fetchPc_inc <= 1'b0;
      _zz_97_ <= 1'b0;
      IBusSimplePlugin_decodePc_pcReg <= externalResetVector;
      _zz_102_ <= 1'b0;
      IBusSimplePlugin_decompressor_bufferValid <= 1'b0;
      _zz_130_ <= 1'b0;
      IBusSimplePlugin_injector_nextPcCalc_valids_0 <= 1'b0;
      IBusSimplePlugin_injector_nextPcCalc_valids_1 <= 1'b0;
      IBusSimplePlugin_injector_nextPcCalc_valids_2 <= 1'b0;
      IBusSimplePlugin_injector_nextPcCalc_valids_3 <= 1'b0;
      IBusSimplePlugin_injector_decodeRemoved <= 1'b0;
      IBusSimplePlugin_pendingCmd <= (3'b000);
      IBusSimplePlugin_rspJoin_discardCounter <= (3'b000);
      _zz_155_ <= 1'b1;
      execute_LightShifterPlugin_isActive <= 1'b0;
      _zz_167_ <= 1'b0;
      CsrPlugin_mstatus_MIE <= 1'b0;
      CsrPlugin_mstatus_MPIE <= 1'b0;
      CsrPlugin_mstatus_MPP <= (2'b11);
      CsrPlugin_mie_MEIE <= 1'b0;
      CsrPlugin_mie_MTIE <= 1'b0;
      CsrPlugin_mie_MSIE <= 1'b0;
      CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_decode <= 1'b0;
      CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_execute <= 1'b0;
      CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_memory <= 1'b0;
      CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_writeBack <= 1'b0;
      CsrPlugin_interrupt_valid <= 1'b0;
      CsrPlugin_hadException <= 1'b0;
      execute_CsrPlugin_wfiWake <= 1'b0;
      _zz_184_ <= (32'b00000000000000000000000000000000);
      execute_arbitration_isValid <= 1'b0;
      memory_arbitration_isValid <= 1'b0;
      writeBack_arbitration_isValid <= 1'b0;
      memory_to_writeBack_REGFILE_WRITE_DATA <= (32'b00000000000000000000000000000000);
      memory_to_writeBack_INSTRUCTION <= (32'b00000000000000000000000000000000);
      _zz_186_ <= 1'b0;
      dBus_cmd_halfPipe_regs_valid <= 1'b0;
      dBus_cmd_halfPipe_regs_ready <= 1'b1;
    end else begin
      if(IBusSimplePlugin_fetchPc_propagatePc)begin
        IBusSimplePlugin_fetchPc_inc <= 1'b0;
      end
      if(IBusSimplePlugin_jump_pcLoad_valid)begin
        IBusSimplePlugin_fetchPc_inc <= 1'b0;
      end
      if(_zz_200_)begin
        IBusSimplePlugin_fetchPc_inc <= 1'b1;
      end
      if(IBusSimplePlugin_fetchPc_samplePcNext)begin
        IBusSimplePlugin_fetchPc_pcReg <= IBusSimplePlugin_fetchPc_pc;
      end
      _zz_97_ <= 1'b1;
      if((decode_arbitration_isFiring && (! IBusSimplePlugin_decodePc_injectedDecode)))begin
        IBusSimplePlugin_decodePc_pcReg <= IBusSimplePlugin_decodePc_pcPlus;
      end
      if(IBusSimplePlugin_jump_pcLoad_valid)begin
        IBusSimplePlugin_decodePc_pcReg <= IBusSimplePlugin_jump_pcLoad_payload;
      end
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        _zz_102_ <= 1'b0;
      end
      if(_zz_100_)begin
        _zz_102_ <= IBusSimplePlugin_iBusRsp_stages_0_output_valid;
      end
      if((IBusSimplePlugin_decompressor_inputBeforeStage_valid && IBusSimplePlugin_decompressor_inputBeforeStage_ready))begin
        IBusSimplePlugin_decompressor_bufferValid <= 1'b0;
      end
      if(_zz_211_)begin
        IBusSimplePlugin_decompressor_bufferValid <= ((! (((! IBusSimplePlugin_decompressor_isRvc) && (! IBusSimplePlugin_iBusRsp_output_payload_pc[1])) && (! IBusSimplePlugin_decompressor_bufferValid))) && (! ((IBusSimplePlugin_decompressor_isRvc && IBusSimplePlugin_iBusRsp_output_payload_pc[1]) && IBusSimplePlugin_decompressor_inputBeforeStage_ready)));
      end
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        IBusSimplePlugin_decompressor_bufferValid <= 1'b0;
      end
      if(IBusSimplePlugin_decompressor_inputBeforeStage_ready)begin
        _zz_130_ <= IBusSimplePlugin_decompressor_inputBeforeStage_valid;
      end
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        _zz_130_ <= 1'b0;
      end
      if((! 1'b0))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_0 <= 1'b1;
      end
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_0 <= 1'b0;
      end
      if((! execute_arbitration_isStuck))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_1 <= IBusSimplePlugin_injector_nextPcCalc_valids_0;
      end
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_1 <= 1'b0;
      end
      if((! memory_arbitration_isStuck))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_2 <= IBusSimplePlugin_injector_nextPcCalc_valids_1;
      end
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_2 <= 1'b0;
      end
      if((! writeBack_arbitration_isStuck))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_3 <= IBusSimplePlugin_injector_nextPcCalc_valids_2;
      end
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_3 <= 1'b0;
      end
      if(decode_arbitration_removeIt)begin
        IBusSimplePlugin_injector_decodeRemoved <= 1'b1;
      end
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        IBusSimplePlugin_injector_decodeRemoved <= 1'b0;
      end
      IBusSimplePlugin_pendingCmd <= IBusSimplePlugin_pendingCmdNext;
      IBusSimplePlugin_rspJoin_discardCounter <= (IBusSimplePlugin_rspJoin_discardCounter - _zz_238_);
      if((IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))begin
        IBusSimplePlugin_rspJoin_discardCounter <= (IBusSimplePlugin_pendingCmd - _zz_240_);
      end
      _zz_155_ <= 1'b0;
      if(_zz_193_)begin
        if(_zz_196_)begin
          execute_LightShifterPlugin_isActive <= 1'b1;
          if(execute_LightShifterPlugin_done)begin
            execute_LightShifterPlugin_isActive <= 1'b0;
          end
        end
      end
      if(execute_arbitration_removeIt)begin
        execute_LightShifterPlugin_isActive <= 1'b0;
      end
      _zz_167_ <= _zz_166_;
      if((! decode_arbitration_isStuck))begin
        CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_decode <= 1'b0;
      end else begin
        CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_decode <= CsrPlugin_exceptionPortCtrl_exceptionValids_decode;
      end
      if((! execute_arbitration_isStuck))begin
        CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_execute <= (CsrPlugin_exceptionPortCtrl_exceptionValids_decode && (! decode_arbitration_isStuck));
      end else begin
        CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_execute <= CsrPlugin_exceptionPortCtrl_exceptionValids_execute;
      end
      if((! memory_arbitration_isStuck))begin
        CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_memory <= (CsrPlugin_exceptionPortCtrl_exceptionValids_execute && (! execute_arbitration_isStuck));
      end else begin
        CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_memory <= CsrPlugin_exceptionPortCtrl_exceptionValids_memory;
      end
      if((! writeBack_arbitration_isStuck))begin
        CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_writeBack <= (CsrPlugin_exceptionPortCtrl_exceptionValids_memory && (! memory_arbitration_isStuck));
      end else begin
        CsrPlugin_exceptionPortCtrl_exceptionValidsRegs_writeBack <= 1'b0;
      end
      CsrPlugin_interrupt_valid <= 1'b0;
      if(_zz_212_)begin
        if(_zz_213_)begin
          CsrPlugin_interrupt_valid <= 1'b1;
        end
        if(_zz_214_)begin
          CsrPlugin_interrupt_valid <= 1'b1;
        end
        if(_zz_215_)begin
          CsrPlugin_interrupt_valid <= 1'b1;
        end
      end
      CsrPlugin_hadException <= CsrPlugin_exception;
      if(_zz_197_)begin
        case(CsrPlugin_targetPrivilege)
          2'b11 : begin
            CsrPlugin_mstatus_MIE <= 1'b0;
            CsrPlugin_mstatus_MPIE <= CsrPlugin_mstatus_MIE;
            CsrPlugin_mstatus_MPP <= CsrPlugin_privilege;
          end
          default : begin
          end
        endcase
      end
      if(_zz_198_)begin
        case(_zz_199_)
          2'b11 : begin
            CsrPlugin_mstatus_MPP <= (2'b00);
            CsrPlugin_mstatus_MIE <= CsrPlugin_mstatus_MPIE;
            CsrPlugin_mstatus_MPIE <= 1'b1;
          end
          default : begin
          end
        endcase
      end
      execute_CsrPlugin_wfiWake <= ({_zz_181_,{_zz_180_,_zz_179_}} != (3'b000));
      if((! writeBack_arbitration_isStuck))begin
        memory_to_writeBack_INSTRUCTION <= memory_INSTRUCTION;
      end
      if((! writeBack_arbitration_isStuck))begin
        memory_to_writeBack_REGFILE_WRITE_DATA <= memory_REGFILE_WRITE_DATA;
      end
      if(((! execute_arbitration_isStuck) || execute_arbitration_removeIt))begin
        execute_arbitration_isValid <= 1'b0;
      end
      if(((! decode_arbitration_isStuck) && (! decode_arbitration_removeIt)))begin
        execute_arbitration_isValid <= decode_arbitration_isValid;
      end
      if(((! memory_arbitration_isStuck) || memory_arbitration_removeIt))begin
        memory_arbitration_isValid <= 1'b0;
      end
      if(((! execute_arbitration_isStuck) && (! execute_arbitration_removeIt)))begin
        memory_arbitration_isValid <= execute_arbitration_isValid;
      end
      if(((! writeBack_arbitration_isStuck) || writeBack_arbitration_removeIt))begin
        writeBack_arbitration_isValid <= 1'b0;
      end
      if(((! memory_arbitration_isStuck) && (! memory_arbitration_removeIt)))begin
        writeBack_arbitration_isValid <= memory_arbitration_isValid;
      end
      if((((! IBusSimplePlugin_iBusRsp_output_ready) && (IBusSimplePlugin_decompressor_inputBeforeStage_valid && IBusSimplePlugin_decompressor_inputBeforeStage_ready)) && (! (IBusSimplePlugin_jump_pcLoad_valid || IBusSimplePlugin_fetcherflushIt))))begin
        IBusSimplePlugin_fetchPc_pcReg[1] <= 1'b1;
      end
      case(execute_CsrPlugin_csrAddress)
        12'b101111000000 : begin
          if(execute_CsrPlugin_writeEnable)begin
            _zz_184_ <= execute_CsrPlugin_writeData[31 : 0];
          end
        end
        12'b001100000000 : begin
          if(execute_CsrPlugin_writeEnable)begin
            CsrPlugin_mstatus_MPP <= execute_CsrPlugin_writeData[12 : 11];
            CsrPlugin_mstatus_MPIE <= _zz_272_[0];
            CsrPlugin_mstatus_MIE <= _zz_273_[0];
          end
        end
        12'b001101000001 : begin
        end
        12'b001100000101 : begin
        end
        12'b001101000100 : begin
        end
        12'b001101000011 : begin
        end
        12'b111111000000 : begin
        end
        12'b001100000100 : begin
          if(execute_CsrPlugin_writeEnable)begin
            CsrPlugin_mie_MEIE <= _zz_275_[0];
            CsrPlugin_mie_MTIE <= _zz_276_[0];
            CsrPlugin_mie_MSIE <= _zz_277_[0];
          end
        end
        12'b001101000010 : begin
        end
        default : begin
        end
      endcase
      if(iBus_cmd_ready)begin
        _zz_186_ <= iBus_cmd_valid;
      end
      if(_zz_216_)begin
        dBus_cmd_halfPipe_regs_valid <= dBus_cmd_valid;
        dBus_cmd_halfPipe_regs_ready <= (! dBus_cmd_valid);
      end else begin
        dBus_cmd_halfPipe_regs_valid <= (! dBus_cmd_halfPipe_ready);
        dBus_cmd_halfPipe_regs_ready <= dBus_cmd_halfPipe_ready;
      end
    end
  end

  always @ (posedge clk) begin
    if(_zz_211_)begin
      IBusSimplePlugin_decompressor_bufferData <= IBusSimplePlugin_iBusRsp_output_payload_rsp_inst[31 : 16];
    end
    if(IBusSimplePlugin_decompressor_inputBeforeStage_ready)begin
      _zz_131_ <= IBusSimplePlugin_decompressor_inputBeforeStage_payload_pc;
      _zz_132_ <= IBusSimplePlugin_decompressor_inputBeforeStage_payload_rsp_error;
      _zz_133_ <= IBusSimplePlugin_decompressor_inputBeforeStage_payload_rsp_inst;
      _zz_134_ <= IBusSimplePlugin_decompressor_inputBeforeStage_payload_isRvc;
    end
    if(IBusSimplePlugin_injector_decodeInput_ready)begin
      IBusSimplePlugin_injector_formal_rawInDecode <= IBusSimplePlugin_decompressor_raw;
    end
    if(IBusSimplePlugin_iBusRsp_stages_1_output_ready)begin
      IBusSimplePlugin_mmu_joinCtx_physicalAddress <= IBusSimplePlugin_mmuBus_rsp_physicalAddress;
      IBusSimplePlugin_mmu_joinCtx_isIoAccess <= IBusSimplePlugin_mmuBus_rsp_isIoAccess;
      IBusSimplePlugin_mmu_joinCtx_allowRead <= IBusSimplePlugin_mmuBus_rsp_allowRead;
      IBusSimplePlugin_mmu_joinCtx_allowWrite <= IBusSimplePlugin_mmuBus_rsp_allowWrite;
      IBusSimplePlugin_mmu_joinCtx_allowExecute <= IBusSimplePlugin_mmuBus_rsp_allowExecute;
      IBusSimplePlugin_mmu_joinCtx_exception <= IBusSimplePlugin_mmuBus_rsp_exception;
      IBusSimplePlugin_mmu_joinCtx_refilling <= IBusSimplePlugin_mmuBus_rsp_refilling;
    end
    if(!(! (((dBus_rsp_ready && memory_MEMORY_ENABLE) && memory_arbitration_isValid) && memory_arbitration_isStuck))) begin
      $display("ERROR DBusSimplePlugin doesn't allow memory stage stall when read happend");
    end
    if(!(! (((writeBack_arbitration_isValid && writeBack_MEMORY_ENABLE) && (! writeBack_MEMORY_STORE)) && writeBack_arbitration_isStuck))) begin
      $display("ERROR DBusSimplePlugin doesn't allow writeback stage stall when read happend");
    end
    if(_zz_193_)begin
      if(_zz_196_)begin
        execute_LightShifterPlugin_amplitudeReg <= (execute_LightShifterPlugin_amplitude - (5'b00001));
      end
    end
    if(_zz_166_)begin
      _zz_168_ <= _zz_48_[11 : 7];
    end
    CsrPlugin_mip_MEIP <= externalInterrupt;
    CsrPlugin_mip_MTIP <= timerInterrupt;
    CsrPlugin_mip_MSIP <= softwareInterrupt;
    CsrPlugin_mcycle <= (CsrPlugin_mcycle + (64'b0000000000000000000000000000000000000000000000000000000000000001));
    if(writeBack_arbitration_isFiring)begin
      CsrPlugin_minstret <= (CsrPlugin_minstret + (64'b0000000000000000000000000000000000000000000000000000000000000001));
    end
    if(_zz_195_)begin
      CsrPlugin_exceptionPortCtrl_exceptionContext_code <= (_zz_183_ ? IBusSimplePlugin_decodeExceptionPort_payload_code : decodeExceptionPort_payload_code);
      CsrPlugin_exceptionPortCtrl_exceptionContext_badAddr <= (_zz_183_ ? IBusSimplePlugin_decodeExceptionPort_payload_badAddr : decodeExceptionPort_payload_badAddr);
    end
    if(DBusSimplePlugin_memoryExceptionPort_valid)begin
      CsrPlugin_exceptionPortCtrl_exceptionContext_code <= DBusSimplePlugin_memoryExceptionPort_payload_code;
      CsrPlugin_exceptionPortCtrl_exceptionContext_badAddr <= DBusSimplePlugin_memoryExceptionPort_payload_badAddr;
    end
    if(_zz_212_)begin
      if(_zz_213_)begin
        CsrPlugin_interrupt_code <= (4'b0111);
        CsrPlugin_interrupt_targetPrivilege <= (2'b11);
      end
      if(_zz_214_)begin
        CsrPlugin_interrupt_code <= (4'b0011);
        CsrPlugin_interrupt_targetPrivilege <= (2'b11);
      end
      if(_zz_215_)begin
        CsrPlugin_interrupt_code <= (4'b1011);
        CsrPlugin_interrupt_targetPrivilege <= (2'b11);
      end
    end
    if(_zz_197_)begin
      case(CsrPlugin_targetPrivilege)
        2'b11 : begin
          CsrPlugin_mcause_interrupt <= (! CsrPlugin_hadException);
          CsrPlugin_mcause_exceptionCode <= CsrPlugin_trapCause;
          CsrPlugin_mepc <= writeBack_PC;
          if(CsrPlugin_hadException)begin
            CsrPlugin_mtval <= CsrPlugin_exceptionPortCtrl_exceptionContext_badAddr;
          end
        end
        default : begin
        end
      endcase
    end
    externalInterruptArray_regNext <= externalInterruptArray;
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_CSR_WRITE_OPCODE <= decode_CSR_WRITE_OPCODE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_BRANCH_CTRL <= _zz_24_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_MEMORY_STORE <= decode_MEMORY_STORE;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_MEMORY_STORE <= execute_MEMORY_STORE;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_MEMORY_STORE <= memory_MEMORY_STORE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_MEMORY_ENABLE <= decode_MEMORY_ENABLE;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_MEMORY_ENABLE <= execute_MEMORY_ENABLE;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_MEMORY_ENABLE <= memory_MEMORY_ENABLE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_CSR_READ_OPCODE <= decode_CSR_READ_OPCODE;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_MMU_FAULT <= execute_MMU_FAULT;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_IS_RVC <= decode_IS_RVC;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_BYPASSABLE_EXECUTE_STAGE <= decode_BYPASSABLE_EXECUTE_STAGE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_BYPASSABLE_MEMORY_STAGE <= decode_BYPASSABLE_MEMORY_STAGE;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_BYPASSABLE_MEMORY_STAGE <= execute_BYPASSABLE_MEMORY_STAGE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC_LESS_UNSIGNED <= decode_SRC_LESS_UNSIGNED;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SHIFT_CTRL <= _zz_21_;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_BRANCH_DO <= execute_BRANCH_DO;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_ALIGNEMENT_FAULT <= execute_ALIGNEMENT_FAULT;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_ALU_CTRL <= _zz_18_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_IS_CSR <= decode_IS_CSR;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_ENV_CTRL <= _zz_15_;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_ENV_CTRL <= _zz_12_;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_ENV_CTRL <= _zz_10_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_INSTRUCTION <= decode_INSTRUCTION;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_INSTRUCTION <= execute_INSTRUCTION;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_PC <= decode_PC;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_PC <= _zz_39_;
    end
    if(((! writeBack_arbitration_isStuck) && (! CsrPlugin_exceptionPortCtrl_exceptionValids_writeBack)))begin
      memory_to_writeBack_PC <= memory_PC;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC2_FORCE_ZERO <= decode_SRC2_FORCE_ZERO;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_RS1 <= decode_RS1;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC2_CTRL <= _zz_8_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC_USE_SUB_LESS <= decode_SRC_USE_SUB_LESS;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_FORMAL_PC_NEXT <= _zz_85_;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_FORMAL_PC_NEXT <= execute_FORMAL_PC_NEXT;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_FORMAL_PC_NEXT <= _zz_84_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC1_CTRL <= _zz_5_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_ALU_BITWISE_CTRL <= _zz_2_;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_BRANCH_CALC <= execute_BRANCH_CALC;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_MEMORY_READ_DATA <= memory_MEMORY_READ_DATA;
    end
    if(((! memory_arbitration_isStuck) && (! execute_arbitration_isStuckByOthers)))begin
      execute_to_memory_REGFILE_WRITE_DATA <= _zz_34_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_REGFILE_WRITE_VALID <= decode_REGFILE_WRITE_VALID;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_REGFILE_WRITE_VALID <= execute_REGFILE_WRITE_VALID;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_REGFILE_WRITE_VALID <= memory_REGFILE_WRITE_VALID;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_MEMORY_ADDRESS_LOW <= execute_MEMORY_ADDRESS_LOW;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_MEMORY_ADDRESS_LOW <= memory_MEMORY_ADDRESS_LOW;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_MMU_RSP_physicalAddress <= execute_MMU_RSP_physicalAddress;
      execute_to_memory_MMU_RSP_isIoAccess <= execute_MMU_RSP_isIoAccess;
      execute_to_memory_MMU_RSP_allowRead <= execute_MMU_RSP_allowRead;
      execute_to_memory_MMU_RSP_allowWrite <= execute_MMU_RSP_allowWrite;
      execute_to_memory_MMU_RSP_allowExecute <= execute_MMU_RSP_allowExecute;
      execute_to_memory_MMU_RSP_exception <= execute_MMU_RSP_exception;
      execute_to_memory_MMU_RSP_refilling <= execute_MMU_RSP_refilling;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_RS2 <= decode_RS2;
    end
    case(execute_CsrPlugin_csrAddress)
      12'b101111000000 : begin
      end
      12'b001100000000 : begin
      end
      12'b001101000001 : begin
        if(execute_CsrPlugin_writeEnable)begin
          CsrPlugin_mepc <= execute_CsrPlugin_writeData[31 : 0];
        end
      end
      12'b001100000101 : begin
        if(execute_CsrPlugin_writeEnable)begin
          CsrPlugin_mtvec_base <= execute_CsrPlugin_writeData[31 : 2];
          CsrPlugin_mtvec_mode <= execute_CsrPlugin_writeData[1 : 0];
        end
      end
      12'b001101000100 : begin
        if(execute_CsrPlugin_writeEnable)begin
          CsrPlugin_mip_MSIP <= _zz_274_[0];
        end
      end
      12'b001101000011 : begin
      end
      12'b111111000000 : begin
      end
      12'b001100000100 : begin
      end
      12'b001101000010 : begin
      end
      default : begin
      end
    endcase
    if(iBus_cmd_ready)begin
      _zz_187_ <= iBus_cmd_payload_pc;
    end
    if(_zz_216_)begin
      dBus_cmd_halfPipe_regs_payload_wr <= dBus_cmd_payload_wr;
      dBus_cmd_halfPipe_regs_payload_address <= dBus_cmd_payload_address;
      dBus_cmd_halfPipe_regs_payload_data <= dBus_cmd_payload_data;
      dBus_cmd_halfPipe_regs_payload_size <= dBus_cmd_payload_size;
    end
  end

endmodule

