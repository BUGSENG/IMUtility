/****************************************************************************
 *
 *   Copyright (c) 2022 IMProject Development Team. All rights reserved.
 *   Authors: Juraj Ciberlin <jciberlin1@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name IMProject nor the names of its contributors may be
 *    used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 ****************************************************************************/

#include "priority_queue.h"

#include <string.h>

static bool
IsPriorityQueueFull(const PriorityQueue_t* const queue) {
    return (queue->size == queue->capacity);
}

static unsigned int
FindHighestPriorityIndex(const PriorityQueue_t* const queue) {
    unsigned int highest_priority = queue->priority_array[0];
    unsigned int index = 0U;
    unsigned int i;

    for (i = 0U; i < queue->size; ++i) {
        if (highest_priority < queue->priority_array[i]) {
            highest_priority = queue->priority_array[i];
            index = i;
        }
    }

    return index;
}

static unsigned int
FindLowestPriorityIndex(const PriorityQueue_t* const queue) {
    unsigned int lowest_priority = queue->priority_array[0];
    unsigned int index = 0U;
    unsigned int i;

    for (i = 0U; i < queue->size; ++i) {
        if (lowest_priority > queue->priority_array[i]) {
            lowest_priority = queue->priority_array[i];
            index = i;
        }
    }

    return index;
}

bool
PriorityQueue_initQueue(PriorityQueue_t* const queue, const uint32_t capacity, const unsigned int element_size, const PriorityQueueItem_t* items) {
    bool status = false;
    if (capacity != 0U) {
        queue->capacity = capacity;
        queue->size = 0U;
        queue->element_size = element_size;
        queue->priority_array = items->priority;
        queue->buffer = items->element;
        status = true;
    }
    return status;
}

bool
PriorityQueue_isEmpty(const PriorityQueue_t* const queue) {
    return (queue->size == 0U);
}

bool
PriorityQueue_enqueue(PriorityQueue_t* const queue, const PriorityQueueItem_t* const item) {
    bool status = false;
    if (!IsPriorityQueueFull(queue)) {
        uint8_t* buffer = queue->buffer;
        if (memcpy(&buffer[queue->size * queue->element_size], item->element, queue->element_size) != NULL_PTR) {
            queue->priority_array[queue->size] = *(item->priority);
            queue->size = queue->size + 1U;
            status = true;
        }
    } else {
        unsigned int lowest_priority_index = FindLowestPriorityIndex(queue);
        if (queue->priority_array[lowest_priority_index] < (*(item->priority))) {
            status = true;
            uint8_t* buffer = queue->buffer;
            queue->size = queue->size - 1U;
            const uint32_t current_size = queue->size;
            for (uint32_t i = lowest_priority_index; i < current_size; ++i) {
                if (memcpy(&buffer[i * queue->element_size], &buffer[(i * queue->element_size) + queue->element_size], queue->element_size) != NULL_PTR) {
                    queue->priority_array[i] = queue->priority_array[i + 1U];
                } else {
                    status = false;
                    break;
                }
            }

            if (status == true) {
                if (memcpy(&buffer[queue->size * queue->element_size], item->element, queue->element_size) != NULL_PTR) {
                    queue->priority_array[queue->size] = *(item->priority);
                    queue->size = queue->size + 1U;
                } else {
                    status = false;
                }
            }
        }
    }
    return status;
}

bool
PriorityQueue_dequeue(PriorityQueue_t* const queue, uint8_t* const element) {
    bool status = false;
    if (!PriorityQueue_isEmpty(queue)) {
        unsigned int highest_priority_index = FindHighestPriorityIndex(queue);
        uint8_t* buffer = queue->buffer;
        if (memcpy(element, &buffer[highest_priority_index * queue->element_size], queue->element_size) != NULL_PTR) {
            status = true;
            queue->size = queue->size - 1U;
            const uint32_t current_size = queue->size;
            for (uint32_t i = highest_priority_index; i < current_size; ++i) {
                if (memcpy(&buffer[i * queue->element_size], &buffer[(i * queue->element_size) + queue->element_size], queue->element_size) != NULL_PTR) {
                    queue->priority_array[i] = queue->priority_array[i + 1U];
                } else {
                    status = false;
                    break;
                }
            }
        }
    }
    return status;
}
