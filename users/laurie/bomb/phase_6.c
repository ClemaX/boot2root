#include <stdint.h>
#include <stddef.h>

typedef struct node
{
	int				content;
	struct node*	next;
} node;

node node1 = {0xfd, 1};
node node2 = {0x2d5, 2};
node node3 = {0x12d, 3};
node node4 = {0x3e5, 4};
node node5 = {0xd4, 5};
node node6 = {0x1b0, 6};

void phase_6(const char *input)
{
    node	*next;
    int		j;
    node	*selected;
    node	*current;
    int		i;
    node	*nodes[6];
    int		nums[6];

    read_six_numbers(input, nums);

	// No number > 6, no duplicates
    i = 0;
    do {
        j = i;
        if (nums[i] > 6)
            explode_bomb();

        while (j < 5)
            if (nums[i] == nums[++j + 1])
                explode_bomb();
        i++;
    } while (i < 6);

	// Select nodes based on index(1..6)
    i = 0;
    do {
        selected = &node1;
        j = 1;
        if (nums[i] > 1) {
            do {
                selected = selected->next;
            } while (j++ < nums[i]);
        }
        nodes[i] = selected;
        i++;
    } while (i < 6);

	// Relink nodes according to selection
    i = 1;
    current = nodes[0];
    do {
        next = nodes[i];
        current->next = next;
        i++;
        current = next;
    } while (i < 6);
    next->next = NULL;

	// Check that nodes contents are in descending order
    i = 0;
    do {
        if (nodes[0]->content < nodes[0]->next->content)
            explode_bomb();
        nodes[0] = nodes[0]->next;
        i++;
    } while (i < 5);
}
