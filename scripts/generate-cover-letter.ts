import { exec } from 'child_process';
import { readFileSync, writeFileSync } from "fs-extra"
import path from "path"
import yaml from "yaml";
import { z } from 'zod';
import util from 'util'

const inputSchema = z.object({
    title: z.string(),
    addresseeCompany: z.string(),
    addressee: z.string(),
    content: z.string(),
});

type CoverLetterInput = z.infer<typeof inputSchema>;

const [_, __, configFileName] = process.argv

const workdir = 'cover-letter-workdir'
const coverLetterTemplatePath = 'cover-letter-template.tex'

const coverLetterTemplate = readFileSync(coverLetterTemplatePath, 'utf8')
const config = inputSchema.parse(yaml.parse(readFileSync(path.resolve(workdir, `${configFileName}.yaml`), 'utf8')))

const hydratedCoverLetter = Object
    .entries(config)
    .reduce(
        (acc, [k, v]) => acc.replace(`!!${k}!!`, v),
        coverLetterTemplate.replace('./cover-letter/profile', '../cover-letter/profile').replace('./tex-deps/', '../tex-deps/'),
    )
writeFileSync(path.resolve(workdir, `${configFileName}.tex`), hydratedCoverLetter)

util
    .promisify(exec)(`cd ${workdir} && xelatex -interaction=nonstopmode ${configFileName}.tex; rm ${configFileName}.log; rm ${configFileName}.aux`)
    .then(console.log)
    .catch(console.error)
