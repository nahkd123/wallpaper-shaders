const Compiler = require("glsl-transpiler");
const fs = require("fs");
const fsp = require("fs/promises");
const path = require("path");
const pngjs = require("pngjs");

const contents = fs.readFileSync(path.join(__dirname, "working-shaders"), "utf-8").split("\n").map(v => v.trim()).filter(v => v);

const compilePass1 = Compiler({
    uniform(name) { return `uniforms.${name}`; }
});

function compileShader(name, glsl, width = 1080, height = 1920) {
    const code = "var gl_FragColor = [0, 0, 0, 0];\n" + compilePass1(glsl) + "\n\nmain();\nreturn gl_FragColor;";
    const prog = new Function("gl_FragCoord", "uniforms", code);
    const backbuffer = new pngjs.PNG({ width, height });
    return {
        glsl, js: code, width, height, backbuffer,
        render() {
            let frame = 0;
            let fps = 60;
            let ftime = () => (1 / fps);
            let time = () => (frame / fps);

            let renderFrame = () => {
                let uniforms = {
                    time: time(), frame: frame, ftime: ftime(),
                    resolution: [width, height],
                    pointerCount: 0,
                    pointers: [],
                    offset: [0, 0],
                    backbuffer,
                };

                for (let y = 0; y < height; y++) {
                    if ((y % 10) == 0) console.log(name, Math.floor(y / height * 100) + "%");

                    for (let x = 0; x < width; x++) {
                        let fragCoord = [x + 0.5, (height - y - 1) + 0.5, 0, 0];
                        let fragColor = prog(fragCoord, uniforms);
                        const pxOffset = ((y * width) + x) * 4;
                        backbuffer.data[pxOffset + 0] = Math.max(Math.min(fragColor[0], 1.0), 0.0) * 255;
                        backbuffer.data[pxOffset + 1] = Math.max(Math.min(fragColor[1], 1.0), 0.0) * 255;
                        backbuffer.data[pxOffset + 2] = Math.max(Math.min(fragColor[2], 1.0), 0.0) * 255;
                        backbuffer.data[pxOffset + 3] = Math.max(Math.min(fragColor[3], 1.0), 0.0) * 255;
                    }
                }
            }

            renderFrame();
            return backbuffer;
        }
    };
}

function toPPM3(img) {
    let text = `P3\n${img.width} ${img.height}\n255\n`;
    for (let i = 0; i < img.width * img.height; i++) {
        text += `${img.data[i*4+0]} ${img.data[i*4+1]} ${img.data[i*4+2]} `;
    }
    return text;
}

// process shaders
// shaders with backbuffer will be rendered at 60 fps for 5 seconds
async function main() {
    if (!fs.existsSync(path.join(__dirname, "..", "buildresult"))) await fsp.mkdir(path.join(__dirname, "..", "buildresult"));

    const code = await Promise.all(contents.map(async v => {
        const glsl = await fsp.readFile(path.join(__dirname, "..", v), "utf-8");
        const prog = compileShader(v, glsl);
        const buff = pngjs.PNG.sync.write(prog.render());
        await fsp.writeFile(path.join(__dirname, "..", "buildresult", path.parse(v).name + ".png"), buff);
        // await fsp.writeFile(path.join(__dirname, "..", "buildresult", path.parse(v).name + ".ppm"), toPPM3(prog.backbuffer));
    }));
}

main();
