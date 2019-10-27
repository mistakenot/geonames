
with open('./data/heirarchy.tsv') as file:
    parents_of = {}
    line_count = 0
    lines_to_take = 100000000
    for line in file:
        if line_count > lines_to_take:
            break
        cells = line.split('\t')
        parent, child = int(cells[0]), int(cells[1])
        if child in parents_of:
            parents_of[child].add(parent)
        else:
            parents_of[child] = set([parent])
        line_count += 1

no_loops = set()

def get_cycles(childId):
    def loop(id, visited, loops):
        if id in visited:
            return visited + [id]
        if id in no_loops:
            return None
        if id not in parents_of:
            return None
        parents = parents_of[id]
        for parentId in parents:
            detected_loop = loop(parentId, visited + [id], loops)
            if detected_loop is not None:
                return detected_loop
        no_loops.add(id)

    return loop(childId, [], [])

for childId in parents_of:
    cycles = get_cycles(childId)
    if cycles is not None:
        print(cycles)