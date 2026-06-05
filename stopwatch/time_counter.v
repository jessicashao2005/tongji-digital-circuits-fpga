// 秒表计时核心：覆盖评分表 13 项（分段记圈 + 查阅版）
//   SW0(mode):  0=正计时  1=定时倒计时
//   SW1(viewsw):查阅开关，拨上后每按 S2 切换查看第 0~4 组记录
//   定时模式未运行未完成 = 设置态：S1加 S0减 设定秒数(0-99)
//   S2启动/继续(查阅态=翻组)  S0停止/设置减  S6复位  S4记圈(分段)
//   data: 0.1s 精度；S4记录的是“距上次S4或起点”的时长
module time_counter(clk, start, stop, rst, lap, inc, frac, mode, viewsw, data, led);
    input         clk, start, stop, rst, lap, inc, frac, mode, viewsw;
    output [15:0] data;
    output reg [7:0] led;

    // ---- 0.1 秒节拍 ----
    reg [31:0] cnt100 = 0;  reg tick = 0;
    always @(posedge clk)
        if (cnt100 == 32'd10000000 - 1) begin cnt100 <= 0; tick <= 1; end
        else begin cnt100 <= cnt100 + 1; tick <= 0; end

    // ---- 去抖采样 ~10ms ----
    reg [19:0] scnt = 0;  reg stick = 0;
    always @(posedge clk)
        if (scnt == 20'd1000000 - 1) begin scnt <= 0; stick <= 1; end
        else begin scnt <= scnt + 1; stick <= 0; end

    // ---- ~2Hz 闪烁信号 ----
    reg [31:0] fcnt = 0;  reg blink = 0;
    always @(posedge clk)
        if (fcnt == 32'd25000000 - 1) begin fcnt <= 0; blink <= ~blink; end
        else fcnt <= fcnt + 1;

    reg run = 0, done = 0, ack = 0;
    reg started = 0;   // 是否已启动过(启动后暂停不再算设置态)
    wire setting = mode & ~run & ~done & ~viewsw & ~started;   // 定时设置态

    // ---- 按键边沿 + S1长按连加 ----
    reg a_st=0,b_st=0, a_sp=0,b_sp=0, a_rs=0,b_rs=0, a_lp=0,b_lp=0;
    reg p_st=0,p_sp=0,p_rs=0,p_lp=0;
    reg [7:0] h_in=0;  reg a_in=0;  reg p_in=0;
    reg [7:0] h_fr=0;  reg a_fr=0;  reg p_fr=0;
    always @(posedge clk) begin
        p_st<=0; p_sp<=0; p_rs<=0; p_lp<=0; p_in<=0; p_fr<=0;
        if (stick) begin
            if (a_st&&!b_st) p_st<=1;   b_st<=a_st; a_st<=start;
            if (a_sp&&!b_sp) p_sp<=1;   b_sp<=a_sp; a_sp<=stop;
            if (a_rs&&!b_rs) p_rs<=1;   b_rs<=a_rs; a_rs<=~rst;   // S6低有效
            if (a_lp&&!b_lp) p_lp<=1;   b_lp<=a_lp; a_lp<=lap;
            a_in <= inc;
            if (a_in) begin h_in<=h_in+1;
                if (h_in==8'd0) p_in<=1;
                else if (h_in>=8'd40 && h_in[3:0]==4'd0) p_in<=1;
            end else h_in<=0;
            a_fr <= frac;
            if (a_fr) begin h_fr<=h_fr+1;
                if (h_fr==8'd0) p_fr<=1;
                else if (h_fr>=8'd40 && h_fr[3:0]==4'd0) p_fr<=1;
            end else h_fr<=0;
        end
    end

    // ---- 设定秒数(0-99) + 小数位(0-9, 0.1s) ----
    reg [6:0] set_sec  = 7'd10;
    reg [3:0] set_frac = 4'd0;
    always @(posedge clk)
        if (p_rs) begin set_sec <= 7'd10; set_frac <= 4'd0; end  // 复位回 10.0s
        else if (setting) begin
            if (p_in & (set_sec < 7'd99)) set_sec <= set_sec + 1;
            if (p_sp & (set_sec > 7'd0 )) set_sec <= set_sec - 1;
            if (p_fr) set_frac <= (set_frac==4'd9) ? 4'd0 : set_frac + 1;  // S3:0-9循环
        end
    // 设定总值(0.1s 单位)
    wire [13:0] set_val = set_sec*14'd10 + set_frac;

    // ---- 主计数 + 5 组分段记录 ----
    reg [13:0] tcnt = 0;
    reg [13:0] mark = 0;                         // 上次记圈/起点的读数
    reg [13:0] lap0=0,lap1=0,lap2=0,lap3=0,lap4=0;
    reg [2:0]  lidx = 0;                         // 下一写入位置 0..4
    reg [2:0]  vidx = 0;                         // 查阅第几组

    // 本段时长 = 计数变化量的绝对值
    wire [13:0] seg = (mode==0) ? (tcnt - mark) : (mark - tcnt);

    always @(posedge clk) begin
        if (p_rs) begin
            run<=0; done<=0; ack<=0; started<=0; vidx<=0; lidx<=0;
            lap0<=0; lap1<=0; lap2<=0; lap3<=0; lap4<=0;
            if (mode) begin tcnt<=14'd100; mark<=14'd100; end  // 复位回 10.0s
            else      begin tcnt<=0;       mark<=0;       end
        end else begin
            // 设置态：tcnt 跟随设定值
            if (setting) begin tcnt<=set_val; mark<=set_val; end
            // 正计时模式未启动时归零(防止从定时设定值残留开始)
            else if (mode==0 & ~started & ~run) begin tcnt<=0; mark<=0; end

            // S2：查阅态翻组；倒计时完成态=确认(常亮)；否则启动
            if (p_st) begin
                if (viewsw)    vidx <= (vidx==3'd4)?3'd0:vidx+1;
                else if (done) ack  <= 1;        // 完成后按S2确认，LED3转常亮
                else           begin run <= 1; started <= 1; end
            end
            // S0 停止（非设置、非查阅）；完成态时 S0 也可确认常亮
            if (p_sp & ~setting & ~viewsw) begin
                if (done) ack <= 1;
                else      run <= 0;
            end

            // S4 记圈：存本段时长，mark 移到当前
            if (p_lp) begin
                case (lidx)
                    0: lap0<=seg; 1: lap1<=seg; 2: lap2<=seg;
                    3: lap3<=seg; 4: lap4<=seg;
                endcase
                lidx <= (lidx==3'd4)?3'd0:lidx+1;
                mark <= tcnt;
            end

            // 计数推进
            if (run & tick) begin
                if (mode==0) begin
                    if (tcnt>=14'd9999) tcnt<=0; else tcnt<=tcnt+1;
                end else begin
                    if (tcnt==0) begin run<=0; done<=1; end   // 到0停住
                    else tcnt<=tcnt-1;
                end
            end
        end
    end

    // ---- 显示来源 ----
    reg [13:0] showv;
    always @(*)
        if (viewsw)
            case (vidx)
                3'd0: showv=lap0; 3'd1: showv=lap1; 3'd2: showv=lap2;
                3'd3: showv=lap3; 3'd4: showv=lap4; default: showv=lap0;
            endcase
        else if (setting) showv = set_val;
        else showv = tcnt;

    wire [3:0] d3 = showv / 1000;
    wire [3:0] d2 = (showv / 100) % 10;
    wire [3:0] d1 = (showv / 10) % 10;
    wire [3:0] d0 = showv % 10;
    assign data = {d3, d2, d1, d0};

    // ---- LED 状态 ----
    //  正计时: [7]运行 [6]暂停
    //  倒计时: [5]运行 [4]暂停 [3]计时完成(到0)
    //  查阅时: [3:0]组号(viewsw 优先)
    always @(*) begin
        led = 8'b0;
        if (mode==0) begin led[7]=run; led[6]=~run; end
        else begin
            led[5]=run;
            if (done) led[3] = ack ? 1'b1 : blink;  // 完成:未确认闪烁,确认后常亮
            else      led[4]=~run;                   // 暂停(未完成)
        end
        if (viewsw) led[3:0] = vidx;   // 查阅模式显示组号
    end
endmodule
