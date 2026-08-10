(() => {
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const statusChip = document.getElementById("gpu-status");
  const statusText = statusChip.querySelector(".chip-text");

  const pointer = { x: 0.5, y: 0.5, tx: 0.5, ty: 0.5 };
  let timeBase = performance.now();
  let started = 0;

  const setStatus = (text, ok) => {
    if (statusText) statusText.textContent = text;
    statusChip.classList.toggle("ok", !!ok);
  };

  window.addEventListener("pointermove", (e) => {
    pointer.tx = e.clientX / window.innerWidth;
    pointer.ty = e.clientY / window.innerHeight;
  }, { passive: true });

  window.addEventListener("touchstart", (e) => {
    const t = e.touches[0];
    if (t) {
      pointer.tx = t.clientX / window.innerWidth;
      pointer.ty = t.clientY / window.innerHeight;
    }
  }, { passive: true });

  window.addEventListener("touchmove", (e) => {
    const t = e.touches[0];
    if (t) {
      pointer.tx = t.clientX / window.innerWidth;
      pointer.ty = t.clientY / window.innerHeight;
    }
  }, { passive: true });

  const AURORA_SRC = `
struct Uniforms {
  time: f32,
  pad: f32,
  res: vec2f,
  mouse: vec2f,
  pad2: vec2f,
};

@group(0) @binding(0) var<uniform> u: Uniforms;

fn hash(p: vec2f) -> f32 {
  return fract(sin(dot(p, vec2f(127.1, 311.7))) * 43758.5453);
}

fn noise(p: vec2f) -> f32 {
  let i = floor(p);
  let f = fract(p);
  let w = f * f * (3.0 - 2.0 * f);
  let a = hash(i);
  let b = hash(i + vec2f(1.0, 0.0));
  let c = hash(i + vec2f(0.0, 1.0));
  let d = hash(i + vec2f(1.0, 1.0));
  return mix(mix(a, b, w.x), mix(c, d, w.x), w.y);
}

fn fbm(p: vec2f) -> f32 {
  var v = 0.0;
  var a = 0.5;
  var q = p;
  for (var i = 0; i < 6; i = i + 1) {
    v = v + a * noise(q);
    q = q * 2.02 + vec2f(11.7, 7.1);
    a = a * 0.5;
  }
  return v;
}

@vertex
fn vs(@builtin(vertex_index) i: u32) -> @builtin(position) vec4f {
  let pts = array<vec2f, 3>(vec2f(-1.0, -1.0), vec2f(3.0, -1.0), vec2f(-1.0, 3.0));
  return vec4f(pts[i], 0.0, 1.0);
}

@fragment
fn fs(@builtin(position) pos: vec4f) -> @location(0) vec4f {
  let uv = pos.xy / u.res;
  let aspect = u.res.x / u.res.y;
  var p = vec2f(uv.x * aspect, uv.y);
  p = p + (u.mouse - vec2f(0.5, 0.5)) * vec2f(0.35, 0.4) * aspect;

  let t = u.time * 0.07;
  let q1 = vec2f(fbm(p * 1.7 + t), fbm(p * 1.7 + vec2f(t * 0.9, -t * 0.5)));
  let q2 = vec2f(fbm(p * 2.2 + q1 * 2.2 + vec2f(t, 0.0)), fbm(p * 2.2 + q1 * 2.2 + vec2f(0.0, t * 0.7)));
  let f = fbm(p * 2.6 + q2 * 2.8);

  let c1 = vec3f(0.13, 0.05, 0.27);
  let c2 = vec3f(0.42, 0.28, 0.75);
  let c3 = vec3f(0.72, 0.42, 0.85);
  let c4 = vec3f(0.98, 0.83, 0.97);

  var col = mix(c1, c2, clamp(f * 1.6, 0.0, 1.0));
  col = mix(col, c3, clamp(q2.x * q2.y * 2.4 + 0.2, 0.0, 1.0) * clamp(f * 1.3, 0.0, 1.0));
  col = mix(col, c4, clamp((q2.y + q1.x) * 0.22, 0.0, 1.0));

  let vig = distance(uv, vec2f(0.5)) * 1.15;
  col = col * (1.0 - smoothstep(0.15, 1.0, vig));

  let mousePush = clamp(distance(u.mouse, vec2f(0.5)) * 2.0, 0.0, 1.0);
  col = col * (1.0 + mousePush * 0.25);
  col = col + (hash(pos.xy * 0.7 + u.time * 6.0) - 0.5) * 0.02;

  return vec4f(col, 1.0);
}
`;

  const GEM_SRC = `
struct Uniforms {
  time: f32,
  pad: f32,
  pointer: vec2f,
};

@group(0) @binding(0) var<uniform> u: Uniforms;

struct VSOut {
  @builtin(position) pos: vec4f,
  @location(0) normal: vec3f,
  @location(1) vpos: vec3f,
  @location(2) color: vec3f,
};

@vertex
fn vs(
  @location(0) position: vec3f,
  @location(1) normal: vec3f,
  @location(2) color: vec3f
) -> VSOut {
  var ang = u.time * 0.55 + sin(u.time * 0.3) * 0.25;
  let ca = cos(ang);
  let sa = sin(ang);

  var p = vec3f(position.x * ca + position.z * sa, position.y, -position.x * sa + position.z * ca);
  p.y = p.y + sin(u.time * 1.1) * 0.14;

  let tx = (u.pointer.y - 0.5) * 0.7;
  let ty = (u.pointer.x - 0.5) * 0.9;
  let c2 = cos(tx);
  let s2 = sin(tx);
  p = vec3f(p.x * c2 - p.y * s2, p.x * s2 + p.y * c2, p.z);
  let c3 = cos(ty);
  let s3 = sin(ty);
  p = vec3f(p.x, p.y * c3 - p.z * s3, p.y * s3 + p.z * c3);

  let n = vec3f(
    normal.x * ca + normal.z * sa,
    normal.y,
    -normal.x * sa + normal.z * ca
  );

  let cam = vec3f(0.0, 0.4, -3.4);
  let pv = p - cam;

  let f = 1.0 / tan(0.6);
  let znear = 0.1;
  let zfar = 30.0;
  let m22 = -(zfar + znear) / (zfar - znear);
  let m23 = -2.0 * znear * zfar / (zfar - znear);
  let m = mat4x4f(
    vec4f(f, 0.0, 0.0, 0.0),
    vec4f(0.0, f, 0.0, 0.0),
    vec4f(0.0, 0.0, m22, -1.0),
    vec4f(0.0, 0.0, m23, 0.0)
  );

  var out: VSOut;
  out.pos = m * vec4f(pv, 1.0);
  out.normal = n;
  out.vpos = p;
  out.color = color;
  return out;
}

@fragment
fn fs(in: VSOut) -> @location(0) vec4f {
  let n = normalize(in.normal);
  let view = normalize(vec3f(0.0, 0.4, -3.4) - in.vpos);
  let light = normalize(vec3f(0.6, 0.9, 0.5));
  let diff = max(dot(n, light), 0.0);
  let half = normalize(light + view);
  let spec = pow(max(dot(n, half), 0.0), 72.0) * 1.1;
  let rim = pow(1.0 - max(dot(n, view), 0.0), 3.2);

  var col = in.color * (0.3 + diff * 0.8);
  col = col + vec3f(1.0, 0.96, 1.0) * spec;
  col = col + vec3f(0.8, 0.55, 0.95) * rim * 0.75;
  col = col + in.color * rim * 0.45;

  return vec4f(col, 1.0);
}
`;

  const v3 = {
    sub: (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]],
    cross: (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]],
    norm: (v) => {
      const l = Math.hypot(v[0], v[1], v[2]) || 1;
      return [v[0] / l, v[1] / l, v[2] / l];
    },
  };

  function buildCrystal() {
    const top = [0, 1.5, 0];
    const bottom = [0, -0.9, 0];
    const equ = [
      [0.75, 0, 0.55],
      [-0.75, 0, 0.55],
      [-0.75, 0, -0.55],
      [0.75, 0, -0.55],
    ];
    const tris = [];
    for (let i = 0; i < 4; i++) {
      const j = (i + 1) % 4;
      tris.push([top, equ[j], equ[i]]);
      tris.push([bottom, equ[i], equ[j]]);
    }
    const pos = [];
    const nor = [];
    const col = [];
    const idx = [];
    const cA = [0.43, 0.31, 0.82];
    const cB = [0.96, 0.8, 0.98];
    for (const tri of tris) {
      const n = v3.norm(v3.cross(v3.sub(tri[1], tri[0]), v3.sub(tri[2], tri[0])));
      const base = pos.length / 3;
      idx.push(base, base + 1, base + 2);
      for (const vtx of tri) {
        pos.push(vtx[0], vtx[1], vtx[2]);
        nor.push(n[0], n[1], n[2]);
        const t = (vtx[1] + 0.9) / 2.4;
        col.push(cA[0] + (cB[0] - cA[0]) * t, cA[1] + (cB[1] - cA[1]) * t, cA[2] + (cB[2] - cA[2]) * t);
      }
    }
    return {
      pos: new Float32Array(pos),
      nor: new Float32Array(nor),
      col: new Float32Array(col),
      idx: new Uint16Array(idx),
    };
  }

  function setupAurora(device) {
    const canvas = document.createElement("canvas");
    document.getElementById("webgpu-bg").appendChild(canvas);
    const ctx = canvas.getContext("webgpu");
    const format = navigator.gpu.getPreferredCanvasFormat();
    ctx.configure({ device, format, alphaMode: "opaque" });

    const uniformBuffer = device.createBuffer({
      size: 32,
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });
    const uniformData = new Float32Array(8);

    const module = device.createShaderModule({ code: AURORA_SRC });
    const bgl = device.createBindGroupLayout({
      entries: [{ binding: 0, visibility: GPUShaderStage.VERTEX | GPUShaderStage.FRAGMENT, buffer: { type: "uniform" } }],
    });
    const pipeline = device.createRenderPipeline({
      layout: device.createPipelineLayout({ bindGroupLayouts: [bgl] }),
      vertex: { module, entryPoint: "vs" },
      fragment: { module, entryPoint: "fs", targets: [{ format }] },
      primitive: { topology: "triangle-list" },
    });
    const bindGroup = device.createBindGroup({
      layout: bgl,
      entries: [{ binding: 0, resource: { buffer: uniformBuffer } }],
    });

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = Math.max(1, Math.floor(window.innerWidth * dpr));
      canvas.height = Math.max(1, Math.floor(window.innerHeight * dpr));
    };
    resize();
    window.addEventListener("resize", resize);

    const frame = () => {
      const w = canvas.width;
      const h = canvas.height;
      uniformData[0] = started;
      uniformData[2] = w;
      uniformData[3] = h;
      uniformData[4] = pointer.x;
      uniformData[5] = pointer.y;
      device.queue.writeBuffer(uniformBuffer, 0, uniformData);

      const encoder = device.createCommandEncoder();
      const pass = encoder.beginRenderPass({
        colorAttachments: [{
          view: ctx.getCurrentTexture().createView(),
          clearValue: { r: 0.08, g: 0.03, b: 0.17, a: 1 },
          loadOp: "clear",
          storeOp: "store",
        }],
      });
      pass.setPipeline(pipeline);
      pass.setBindGroup(0, bindGroup);
      pass.draw(3);
      pass.end();
      device.queue.submit([encoder.finish()]);
    };

    return { frame, canvas };
  }

  function setupGem(device) {
    const canvas = document.getElementById("gem");
    if (!canvas) return null;
    const ctx = canvas.getContext("webgpu");
    const format = navigator.gpu.getPreferredCanvasFormat();
    ctx.configure({ device, format, alphaMode: "premultiplied" });

    const data = buildCrystal();
    const vertexBuffer = device.createBuffer({
      size: data.pos.byteLength + data.nor.byteLength + data.col.byteLength,
      usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
    });
    const indexBuffer = device.createBuffer({
      size: data.idx.byteLength,
      usage: GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(vertexBuffer, 0, data.pos);
    device.queue.writeBuffer(vertexBuffer, data.pos.byteLength, data.nor);
    device.queue.writeBuffer(vertexBuffer, data.pos.byteLength + data.nor.byteLength, data.col);
    device.queue.writeBuffer(indexBuffer, 0, data.idx);

    const uniformBuffer = device.createBuffer({
      size: 16,
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });
    const uniformData = new Float32Array(4);

    const module = device.createShaderModule({ code: GEM_SRC });
    const bgl = device.createBindGroupLayout({
      entries: [{ binding: 0, visibility: GPUShaderStage.VERTEX | GPUShaderStage.FRAGMENT, buffer: { type: "uniform" } }],
    });
    const pipeline = device.createRenderPipeline({
      layout: device.createPipelineLayout({ bindGroupLayouts: [bgl] }),
      vertex: {
        module,
        entryPoint: "vs",
        buffers: [{
          arrayStride: 36,
          attributes: [
            { shaderLocation: 0, offset: 0, format: "float32x3" },
            { shaderLocation: 1, offset: 12, format: "float32x3" },
            { shaderLocation: 2, offset: 24, format: "float32x3" },
          ],
        }],
      },
      fragment: {
        module,
        entryPoint: "fs",
        targets: [{
          format,
          blend: {
            color: { srcFactor: "one", dstFactor: "one-minus-src-alpha", operation: "add" },
            alpha: { srcFactor: "one", dstFactor: "one-minus-src-alpha", operation: "add" },
          },
        }],
      },
      primitive: { topology: "triangle-list" },
      depthStencil: {
        format: "depth24plus",
        depthWriteEnabled: true,
        depthCompare: "less",
      },
      multisample: { count: 4 },
    });
    const bindGroup = device.createBindGroup({
      layout: bgl,
      entries: [{ binding: 0, resource: { buffer: uniformBuffer } }],
    });

    let colorTex = null;
    let depthTex = null;

    const makeTargets = () => {
      if (colorTex) colorTex.destroy();
      if (depthTex) depthTex.destroy();
      colorTex = device.createTexture({
        size: [canvas.width, canvas.height],
        sampleCount: 4,
        format,
        usage: GPUTextureUsage.RENDER_ATTACHMENT,
      });
      depthTex = device.createTexture({
        size: [canvas.width, canvas.height],
        sampleCount: 4,
        format: "depth24plus",
        usage: GPUTextureUsage.RENDER_ATTACHMENT,
      });
    };

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const w = Math.max(1, Math.floor(canvas.clientWidth * dpr));
      const h = Math.max(1, Math.floor(canvas.clientHeight * dpr));
      if (w !== canvas.width || h !== canvas.height) {
        canvas.width = w;
        canvas.height = h;
        makeTargets();
      }
    };
    resize();
    window.addEventListener("resize", resize);
    new ResizeObserver(resize).observe(canvas);

    const frame = () => {
      uniformData[0] = started;
      uniformData[2] = pointer.x;
      uniformData[3] = pointer.y;
      device.queue.writeBuffer(uniformBuffer, 0, uniformData);

      const encoder = device.createCommandEncoder();
      const pass = encoder.beginRenderPass({
        colorAttachments: [{
          view: colorTex.createView(),
          resolveTarget: ctx.getCurrentTexture().createView(),
          clearValue: { r: 0, g: 0, b: 0, a: 0 },
          loadOp: "clear",
          storeOp: "discard",
        }],
        depthStencilAttachment: {
          view: depthTex.createView(),
          depthLoadOp: "clear",
          depthClearValue: 1.0,
          depthStoreOp: "discard",
        },
      });
      pass.setPipeline(pipeline);
      pass.setVertexBuffer(0, vertexBuffer);
      pass.setIndexBuffer(indexBuffer, "uint16");
      pass.setBindGroup(0, bindGroup);
      pass.drawIndexed(data.idx.length);
      pass.end();
      device.queue.submit([encoder.finish()]);
    };

    return { frame };
  }

  async function init() {
    let aurora = null;
    let gem = null;
    let ok = false;

    if ("gpu" in navigator) {
      try {
        const adapter = await navigator.gpu.requestAdapter();
        if (adapter) {
          const device = await adapter.requestDevice();
          aurora = setupAurora(device);
          gem = setupGem(device);
          ok = true;
        }
      } catch (err) {
        console.warn("WebGPU init failed:", err);
      }
    }

    if (ok) {
      setStatus("Nền cảnh đang chạy bằng WebGPU", true);
    } else {
      document.body.classList.add("no-webgpu");
      const bg = document.getElementById("webgpu-bg");
      if (bg) bg.style.display = "none";
      const gem = document.getElementById("gem");
      if (gem) gem.style.display = "none";
      const caption = document.querySelector(".gem-caption");
      if (caption) caption.style.display = "none";
      setStatus("WebGPU không khả dụng — đang dùng chế độ mềm mại thay thế", false);
    }

    const renderOnce = (t) => {
      started = (t - timeBase) / 1000;
      if (aurora) aurora.frame();
      if (gem) gem.frame();
    };

    const loop = (t) => {
      renderOnce(t);
      if (!reduced) requestAnimationFrame(loop);
    };

    if (reduced) {
      renderOnce(performance.now());
    } else {
      requestAnimationFrame(loop);
    }
  }

  const replay = document.getElementById("cta-replay");
  if (replay) {
    replay.addEventListener("click", () => {
      timeBase = performance.now();
      replay.animate(
        [
          { transform: "scale(1)" },
          { transform: "scale(0.94)" },
          { transform: "scale(1)" },
        ],
        { duration: 500, easing: "cubic-bezier(0.22, 1, 0.36, 1)" }
      );
    });
  }

  const nav = document.getElementById("nav");
  const onScroll = () => nav.classList.toggle("scrolled", window.scrollY > 8);
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  const revealConfig = [
    [".hero-copy", 1],
    [".gem-wrap", 1],
    [".section-head", 1],
    [".card", 3],
    [".tech-panel", 1],
    [".step", 3],
    [".cta-band", 1],
    [".footer-inner", 1],
  ];
  const targets = [];
  for (const [sel, stagger] of revealConfig) {
    document.querySelectorAll(sel).forEach((el, i) => {
      el.classList.add("reveal");
      el.style.setProperty("--d", `${(i % stagger) * 90}ms`);
      targets.push(el);
    });
  }

  if (!reduced && "IntersectionObserver" in window) {
    const io = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          io.unobserve(entry.target);
        }
      }
    }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
    targets.forEach((el) => io.observe(el));
  } else {
    targets.forEach((el) => el.classList.add("in"));
  }

  init();
})();
