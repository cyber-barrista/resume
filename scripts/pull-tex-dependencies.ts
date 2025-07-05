import { Downloader } from "nodejs-file-downloader";
import { ensureDir, remove } from "fs-extra"

const gitHabHashVersions = {
    awesomeCv: "dc50c6d2ec6b098423091166d232b5830d6740d2",
    draculaTheme: "4faa27fe5b34b08f01282faee57c82035cc6039b",
} as const

type Dependency = { name: string, url: string }

const dependencies: Dependency[] = [
    {
        name: "awesome-cv.cls",
        url: `https://raw.githubusercontent.com/posquit0/Awesome-CV/${gitHabHashVersions.awesomeCv}/awesome-cv.cls`
    },
    {
        name: "draculatheme.sty",
        url: `https://raw.githubusercontent.com/dracula/latex/${gitHabHashVersions.draculaTheme}/draculatheme.sty`
    }
] as const

const dependencyFolder = "tex-deps"

async function downloadDependencies(targetLocation: string, dependencies: Dependency[]) {
    await remove(targetLocation)
    await ensureDir(targetLocation)

    const downloads = dependencies
        .map(({ name, url }) => ({ url, directory: targetLocation, fileName: name }))
        .map(config => new Downloader(config).download())

    try {
        const evidence = await Promise.all(downloads)
        console.log(JSON.stringify(evidence, null, 2));
    } catch (error) {
        console.error("Something went horribly wrong", error)
    }
}

downloadDependencies(dependencyFolder, dependencies)
