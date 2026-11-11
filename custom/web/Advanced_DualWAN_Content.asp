<!DOCTYPE html>
<html>
<head>
<title>Newifi D2 - 双WAN与多线负载均衡拓扑</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>

<style>
/* Dual WAN Interactive Topology Canvas */
.topology-container {
    background: radial-gradient(circle at 50% 20%, #1a2332 0%, #0d121c 100%);
    border: 1px solid #2d3b55;
    border-radius: 12px;
    padding: 24px;
    margin-bottom: 24px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.5);
    color: #e2e8f0;
    position: relative;
    user-select: none;
}
.topo-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid rgba(255,255,255,0.1);
    padding-bottom: 12px;
    margin-bottom: 20px;
}
.topo-title {
    font-size: 18px;
    font-weight: 700;
    color: #38bdf8;
    display: flex;
    align-items: center;
    gap: 8px;
}
.topo-badge {
    background: rgba(56, 189, 248, 0.2);
    color: #38bdf8;
    padding: 3px 10px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
    border: 1px solid rgba(56, 189, 248, 0.4);
}
.isps-rack {
    display: flex;
    justify-content: space-around;
    margin-bottom: 30px;
}
.isp-node {
    background: rgba(30, 41, 59, 0.8);
    border: 2px dashed #475569;
    border-radius: 10px;
    padding: 12px 24px;
    text-align: center;
    cursor: grab;
    transition: all 0.3s;
    min-width: 170px;
}
.isp-node:hover {
    border-color: #38bdf8;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(56, 189, 248, 0.3);
}
.isp-node.primary {
    border-color: #22c55e;
    border-style: solid;
    cursor: default;
}
.isp-cable-head {
    display: inline-block;
    width: 24px;
    height: 14px;
    background: #0284c7;
    border-radius: 3px;
    margin-top: 6px;
    position: relative;
    cursor: grab;
}
.isp-cable-head::after {
    content: '';
    position: absolute;
    width: 10px;
    height: 4px;
    background: #e0f2fe;
    bottom: -4px;
    left: 7px;
    border-radius: 1px;
}
.chassis-box {
    background: #1e293b;
    border: 2px solid #334155;
    border-radius: 10px;
    padding: 20px;
    box-shadow: inset 0 2px 6px rgba(0,0,0,0.6);
}
.ports-row {
    display: flex;
    justify-content: center;
    gap: 16px;
    flex-wrap: wrap;
}
.rj45-port {
    width: 100px;
    height: 125px;
    background: #0f172a;
    border: 2px solid #334155;
    border-radius: 8px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-between;
    padding: 10px 6px;
    transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
}
.rj45-port.droppable-target {
    border: 2px dashed #38bdf8;
    background: rgba(56, 189, 248, 0.1);
}
.rj45-port.port-wan {
    border-color: #22c55e;
    box-shadow: 0 0 14px rgba(34, 197, 94, 0.25);
}
.rj45-port.port-wan2 {
    border-color: #0ea5e9;
    box-shadow: 0 0 14px rgba(14, 165, 233, 0.35);
}
.rj45-port.port-lan {
    border-color: #64748b;
}
.jack-hole {
    width: 52px;
    height: 38px;
    background: #020617;
    border: 2px solid #1e293b;
    border-radius: 4px;
    margin: 8px 0;
    position: relative;
}
.pins {
    position: absolute;
    top: 3px;
    left: 6px;
    right: 6px;
    display: flex;
    justify-content: space-between;
}
.pin {
    width: 2px;
    height: 8px;
    background: #eab308;
}
.port-led {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #22c55e;
    box-shadow: 0 0 8px #22c55e;
}
.port-led.off {
    background: #475569;
    box-shadow: none;
}
.port-name {
    font-size: 13px;
    font-weight: 700;
    color: #f1f5f9;
}
.port-role {
    font-size: 10px;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 4px;
    text-transform: uppercase;
}
.role-wan { background: #22c55e; color: #022c22; }
.role-wan2 { background: #0ea5e9; color: #082f49; }
.role-lan { background: #475569; color: #f8fafc; }

.quick-actions {
    margin-top: 20px;
    display: flex;
    justify-content: center;
    gap: 10px;
    flex-wrap: wrap;
}
.btn-assign {
    background: rgba(14, 165, 233, 0.15);
    border: 1px solid #0ea5e9;
    color: #38bdf8;
    padding: 6px 14px;
    border-radius: 6px;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
}
.btn-assign:hover {
    background: #0ea5e9;
    color: #ffffff;
}

/* Status Matrix Cards */
.status-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 16px;
    margin-bottom: 24px;
}
.status-card {
    background: #1e293b;
    border: 1px solid #334155;
    border-radius: 10px;
    padding: 16px;
}
.status-card-title {
    font-size: 14px;
    font-weight: 700;
    color: #94a3b8;
    margin-bottom: 10px;
    display: flex;
    justify-content: space-between;
}
.status-row {
    display: flex;
    justify-content: space-between;
    font-size: 12px;
    padding: 4px 0;
    border-bottom: 1px solid rgba(255,255,255,0.05);
}
.status-val {
    font-weight: 600;
    color: #f8fafc;
    font-family: monospace;
}
</style>

<script>
var dualwan_enable = '<% nvram_get_x("", "dualwan_enable"); %>' || '1';
var dualwan_port   = '<% nvram_get_x("", "dualwan_port"); %>' || '1';
var dualwan_proto  = '<% nvram_get_x("", "dualwan_proto"); %>' || 'dhcp';
var dualwan_mode   = '<% nvram_get_x("", "dualwan_mode"); %>' || 'balance';

function initial() {
    show_menu(5, 3, 4);
    updateUI();
}

function updateUI() {
    $('#select_port').val(dualwan_port);
    $('#dualwan_proto_sel').val(dualwan_proto);
    $('#dualwan_mode_sel').val(dualwan_mode);
    
    toggleProtoFields();
    renderPorts();
}

function renderPorts() {
    for (var i = 1; i <= 4; i++) {
        var $p = $('#port_lan' + i);
        var $role = $('#role_lan' + i);
        if (dualwan_enable == '1' && dualwan_port == i) {
            $p.removeClass('port-lan').addClass('port-wan2');
            $role.removeClass('role-lan').addClass('role-wan2').text('WAN2 (宽带2)');
        } else {
            $p.removeClass('port-wan2').addClass('port-lan');
            $role.removeClass('role-lan role-wan2').addClass('role-lan').text('LAN ' + i);
        }
    }
}

function setPort(p) {
    dualwan_port = p.toString();
    $('#input_dualwan_port').val(dualwan_port);
    renderPorts();
}

function toggleProtoFields() {
    var p = $('#dualwan_proto_sel').val();
    if (p == 'pppoe') {
        $('.pppoe-field').show();
        $('.static-field').hide();
    } else if (p == 'static') {
        $('.pppoe-field').hide();
        $('.static-field').show();
    } else {
        $('.pppoe-field').hide();
        $('.static-field').hide();
    }
}

function handleDragStart(ev) {
    ev.dataTransfer.setData("text/plain", "WAN2_UPLINK");
}

function handleDragOver(ev) {
    ev.preventDefault();
    $(ev.currentTarget).addClass('droppable-target');
}

function handleDragLeave(ev) {
    $(ev.currentTarget).removeClass('droppable-target');
}

function handleDrop(ev, portNum) {
    ev.preventDefault();
    $(ev.currentTarget).removeClass('droppable-target');
    setPort(portNum);
}

function applySettings() {
    $('#input_dualwan_enable').val($('#toggle_enable').is(':checked') ? '1' : '0');
    $('#input_dualwan_port').val(dualwan_port);
    $('#input_dualwan_proto').val($('#dualwan_proto_sel').val());
    $('#input_dualwan_mode').val($('#dualwan_mode_sel').val());
    $('#input_dualwan_user').val($('#pppoe_user').val());
    $('#input_dualwan_pass').val($('#pppoe_pass').val());
    
    showLoading();
    document.form.submit();
}
</script>
</head>

<body onload="initial();">
<div id="Loading" class="popup_bg"></div>

<div class="wrapper">
    <div class="container-fluid" style="padding-right: 0px">
        <div class="row-fluid">
            <div class="span12">
                <div class="box well gradient">
                    <!-- Heading -->
                    <div class="heading">
                        <h3>双WAN与多线负载均衡 (Dual WAN ECMP)</h3>
                    </div>

                    <div class="content" style="padding: 20px;">
                        
                        <!-- Interactive Drag & Drop Topology Board -->
                        <div class="topology-container">
                            <div class="topo-header">
                                <div class="topo-title">
                                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>
                                    Newifi D2 物理面板交互拓扑
                                </div>
                                <div>
                                    <span class="topo-badge">拖拽线缆或点击指定 WAN2 物理端口</span>
                                </div>
                            </div>

                            <!-- ISP Uplink Nodes -->
                            <div class="isps-rack">
                                <div class="isp-node primary">
                                    <div style="font-weight:700; color:#4ade80;">主宽带 (ISP 1)</div>
                                    <div style="font-size:11px; color:#94a3b8;">固定绑定物理 WAN 口</div>
                                    <div class="isp-cable-head" style="background:#22c55e;"></div>
                                </div>

                                <div class="isp-node" draggable="true" ondragstart="handleDragStart(event);">
                                    <div style="font-weight:700; color:#38bdf8;">次宽带 (ISP 2)</div>
                                    <div style="font-size:11px; color:#cbd5e1;">可拖拽至任意 LAN 口</div>
                                    <div class="isp-cable-head" title="按住拖拽至下方 LAN 端口"></div>
                                </div>
                            </div>

                            <!-- Chassis Body -->
                            <div class="chassis-box">
                                <div class="ports-row">
                                    <!-- Physical WAN (Port 0) -->
                                    <div class="rj45-port port-wan">
                                        <div class="port-led"></div>
                                        <div class="port-name">WAN</div>
                                        <div class="jack-hole">
                                            <div class="pins"><div class="pin"></div><div class="pin"></div><div class="pin"></div><div class="pin"></div></div>
                                        </div>
                                        <span class="port-role role-wan">WAN 1 (主宽带)</span>
                                    </div>

                                    <!-- LAN 1 -->
                                    <div class="rj45-port port-lan" id="port_lan1" ondragover="handleDragOver(event);" ondragleave="handleDragLeave(event);" ondrop="handleDrop(event, 1);" onclick="setPort(1);">
                                        <div class="port-led"></div>
                                        <div class="port-name">LAN 1</div>
                                        <div class="jack-hole">
                                            <div class="pins"><div class="pin"></div><div class="pin"></div><div class="pin"></div><div class="pin"></div></div>
                                        </div>
                                        <span class="port-role role-lan" id="role_lan1">LAN 1</span>
                                    </div>

                                    <!-- LAN 2 -->
                                    <div class="rj45-port port-lan" id="port_lan2" ondragover="handleDragOver(event);" ondragleave="handleDragLeave(event);" ondrop="handleDrop(event, 2);" onclick="setPort(2);">
                                        <div class="port-led"></div>
                                        <div class="port-name">LAN 2</div>
                                        <div class="jack-hole">
                                            <div class="pins"><div class="pin"></div><div class="pin"></div><div class="pin"></div><div class="pin"></div></div>
                                        </div>
                                        <span class="port-role role-lan" id="role_lan2">LAN 2</span>
                                    </div>

                                    <!-- LAN 3 -->
                                    <div class="rj45-port port-lan" id="port_lan3" ondragover="handleDragOver(event);" ondragleave="handleDragLeave(event);" ondrop="handleDrop(event, 3);" onclick="setPort(3);">
                                        <div class="port-led"></div>
                                        <div class="port-name">LAN 3</div>
                                        <div class="jack-hole">
                                            <div class="pins"><div class="pin"></div><div class="pin"></div><div class="pin"></div><div class="pin"></div></div>
                                        </div>
                                        <span class="port-role role-lan" id="role_lan3">LAN 3</span>
                                    </div>

                                    <!-- LAN 4 -->
                                    <div class="rj45-port port-lan" id="port_lan4" ondragover="handleDragOver(event);" ondragleave="handleDragLeave(event);" ondrop="handleDrop(event, 4);" onclick="setPort(4);">
                                        <div class="port-led"></div>
                                        <div class="port-name">LAN 4</div>
                                        <div class="jack-hole">
                                            <div class="pins"><div class="pin"></div><div class="pin"></div><div class="pin"></div><div class="pin"></div></div>
                                        </div>
                                        <span class="port-role role-lan" id="role_lan4">LAN 4</span>
                                    </div>
                                </div>
                            </div>

                            <!-- Fast Switch Preset Buttons -->
                            <div class="quick-actions">
                                <span style="font-size:12px; color:#94a3b8; align-self:center;">一键将 WAN2 绑定至：</span>
                                <button type="button" class="btn-assign" onclick="setPort(1);">LAN 1 (推荐)</button>
                                <button type="button" class="btn-assign" onclick="setPort(2);">LAN 2</button>
                                <button type="button" class="btn-assign" onclick="setPort(3);">LAN 3</button>
                                <button type="button" class="btn-assign" onclick="setPort(4);">LAN 4</button>
                            </div>
                        </div>

                        <!-- Status Dashboard -->
                        <div class="status-grid">
                            <div class="status-card">
                                <div class="status-card-title">
                                    <span>WAN 1 (主宽带 / eth2.2)</span>
                                    <span style="color:#22c55e;">● 运行中</span>
                                </div>
                                <div class="status-row"><span>接入协议</span><span class="status-val"><% nvram_get_x("", "wan_proto"); %></span></div>
                                <div class="status-row"><span>IP 地址</span><span class="status-val"><% nvram_get_x("", "wan0_ipaddr"); %></span></div>
                                <div class="status-row"><span>默认网关</span><span class="status-val"><% nvram_get_x("", "wan0_gateway"); %></span></div>
                                <div class="status-row"><span>链路速率</span><span class="status-val">1000M 全双工</span></div>
                            </div>

                            <div class="status-card">
                                <div class="status-card-title">
                                    <span>WAN 2 (次宽带 / eth2.3)</span>
                                    <span style="color:#0ea5e9;" id="wan2_status_badge">● 已就绪</span>
                                </div>
                                <div class="status-row"><span>物理端口</span><span class="status-val" id="disp_wan2_port">LAN <% nvram_get_x("", "dualwan_port"); %></span></div>
                                <div class="status-row"><span>接入协议</span><span class="status-val"><% nvram_get_x("", "dualwan_proto"); %></span></div>
                                <div class="status-row"><span>多路径权重</span><span class="status-val">Weight 1 (ECMP 50%)</span></div>
                                <div class="status-row"><span>带宽聚合</span><span class="status-val" style="color:#38bdf8;">1 + 1 聚合加速</span></div>
                            </div>
                        </div>

                        <!-- Form Configuration Table -->
                        <table class="table table-striped" style="margin-bottom: 20px;">
                            <thead>
                                <tr>
                                    <th colspan="2">双WAN多路径路由与接入参数</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <th width="30%">启用双WAN功能</th>
                                    <td>
                                        <input type="checkbox" id="toggle_enable" checked="checked">
                                        <span class="help-inline" style="margin-left: 10px;">开启硬件级双 WAN 接入与内核 ECMP 负载均衡</span>
                                    </td>
                                </tr>
                                <tr>
                                    <th>次级 WAN (WAN2) 物理端口</th>
                                    <td>
                                        <select id="select_port" onchange="setPort(this.value);" class="input-medium">
                                            <option value="1">LAN 1 (默认推荐)</option>
                                            <option value="2">LAN 2</option>
                                            <option value="3">LAN 3</option>
                                            <option value="4">LAN 4</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr>
                                    <th>多WAN叠加模式</th>
                                    <td>
                                        <select id="dualwan_mode_sel" class="input-large">
                                            <option value="balance">均衡负载叠加 (ECMP 1:1 动态哈希聚合)</option>
                                            <option value="ratio2">不等比权重叠加 (WAN1 2:1 WAN2)</option>
                                            <option value="failover">主备故障自动转移 (WAN1 断线切 WAN2)</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr>
                                    <th>WAN2 接入方式</th>
                                    <td>
                                        <select id="dualwan_proto_sel" onchange="toggleProtoFields();" class="input-medium">
                                            <option value="dhcp">DHCP (动态获取 - 光猫自动分配)</option>
                                            <option value="pppoe">PPPoE (独立宽带拨号)</option>
                                            <option value="static">Static (静态指定 IP)</option>
                                        </select>
                                    </td>
                                </tr>
                                <tr class="pppoe-field" style="display:none;">
                                    <th>WAN2 PPPoE 账号</th>
                                    <td>
                                        <input type="text" id="pppoe_user" class="input-large" value="<% nvram_get_x("", "dualwan_user"); %>">
                                    </td>
                                </tr>
                                <tr class="pppoe-field" style="display:none;">
                                    <th>WAN2 PPPoE 密码</th>
                                    <td>
                                        <input type="password" id="pppoe_pass" class="input-large" value="<% nvram_get_x("", "dualwan_pass"); %>">
                                    </td>
                                </tr>
                                <tr>
                                    <th>内核哈希策略</th>
                                    <td>
                                        <code>fib_multipath_hash_policy = 1</code>
                                        <span class="help-inline" style="color:#10b981; font-weight:600;">(L4 四元组哈希，兼顾多线程下载翻倍与游戏/网银防断流)</span>
                                    </td>
                                </tr>
                            </tbody>
                        </table>

                        <!-- Save & Apply Button -->
                        <div class="form-actions" style="margin-bottom: 0px; text-align: center;">
                            <input class="btn btn-primary" style="min-width: 160px; padding: 8px 24px; font-weight: bold; font-size: 14px;" type="button" value="应用并启动双WAN" onclick="applySettings();" />
                        </div>

                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Hidden Apply Form -->
<form method="post" name="form" action="/apply.cgi">
<input type="hidden" name="current_page" value="Advanced_DualWAN_Content.asp">
<input type="hidden" name="next_page" value="Advanced_DualWAN_Content.asp">
<input type="hidden" name="action_mode" value="Apply">
<input type="hidden" name="action_script" value="restart_dualwan">
<input type="hidden" id="input_dualwan_enable" name="dualwan_enable" value="1">
<input type="hidden" id="input_dualwan_port" name="dualwan_port" value="1">
<input type="hidden" id="input_dualwan_proto" name="dualwan_proto" value="dhcp">
<input type="hidden" id="input_dualwan_mode" name="dualwan_mode" value="balance">
<input type="hidden" id="input_dualwan_user" name="dualwan_user" value="">
<input type="hidden" id="input_dualwan_pass" name="dualwan_pass" value="">
</form>

</body>
</html>
