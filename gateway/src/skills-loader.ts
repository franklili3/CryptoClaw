/**
 * CryptoClaw Gateway - Skills Loader
 *
 * 动态加载所有 skills 并注册到 OpenClaw
 */

import * as fs from 'fs';
import * as path from 'path';

export interface Skill {
  name: string;
  description: string;
  path: string;
  metadata?: Record<string, unknown>;
}

const SKILLS_DIR = path.join(__dirname, '../skills');

/**
 * 扫描 skills 目录，加载所有 SKILL.md
 */
export function loadSkills(): Skill[] {
  const skills: Skill[] = [];

  if (!fs.existsSync(SKILLS_DIR)) {
    console.warn('Skills directory not found:', SKILLS_DIR);
    return skills;
  }

  const dirs = fs.readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

  for (const dir of dirs) {
    const skillPath = path.join(SKILLS_DIR, dir);
    const skillMdPath = path.join(skillPath, 'SKILL.md');

    if (fs.existsSync(skillMdPath)) {
      try {
        const content = fs.readFileSync(skillMdPath, 'utf8');
        const skill = parseSkillMd(content, dir, skillPath);
        skills.push(skill);
        console.log(`[skills] Loaded: ${skill.name}`);
      } catch (error) {
        console.error(`[skills] Failed to load ${dir}:`, error);
      }
    }
  }

  return skills;
}

/**
 * 解析 SKILL.md 文件
 */
function parseSkillMd(content: string, dir: string, skillPath: string): Skill {
  // 解析 YAML frontmatter
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
  let metadata: Record<string, unknown> = {};

  if (frontmatterMatch) {
    const yaml = frontmatterMatch[1];
    // 简单的 YAML 解析 (支持基本键值对)
    for (const line of yaml.split('\n')) {
      const [key, ...valueParts] = line.split(':');
      if (key && valueParts.length > 0) {
        let value = valueParts.join(':').trim();
        // 移除引号
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.slice(1, -1);
        }
        metadata[key.trim()] = value;
      }
    }
  }

  return {
    name: (metadata.name as string) || dir,
    description: (metadata.description as string) || '',
    path: skillPath,
    metadata,
  };
}

/**
 * 获取 skill 列表 API
 */
export function getSkillsList(): { name: string; description: string }[] {
  const skills = loadSkills();
  return skills.map(s => ({
    name: s.name,
    description: s.description,
  }));
}

/**
 * 检查 skill 是否存在
 */
export function hasSkill(name: string): boolean {
  const skills = loadSkills();
  return skills.some(s => s.name === name);
}

/**
 * 获取 skill 路径
 */
export function getSkillPath(name: string): string | null {
  const skills = loadSkills();
  const skill = skills.find(s => s.name === name);
  return skill ? skill.path : null;
}
